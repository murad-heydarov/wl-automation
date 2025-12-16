#!/bin/bash
# deploy-wl.sh - Advanced WL Automation Deployment Script
# Usage: ./deploy-wl.sh <wl-name> [options]
#
# Options:
#   --skip-mailgun-verification    Skip Mailgun domain verification
#   --dry-run                      Show what would be deployed without applying
#   --resume-from=<step>           Resume from specific step (1-9)
#   --help                         Show this help message

set -e

# ============================================================================
# Configuration
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WL_NAME="${1}"
SKIP_MAILGUN_VERIFICATION=false
DRY_RUN=false
RESUME_FROM=1

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
    echo ""
    echo -e "${CYAN}============================================================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}============================================================================${NC}"
}

print_step() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}▶ Step $1: $2${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ ERROR: $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  WARNING: $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

show_help() {
    cat << EOF
WL Automation Deployment Script

Usage: ./deploy-wl.sh <wl-name> [options]

Arguments:
  wl-name                        Name of WL config (e.g., afftech, liravegas)

Options:
  --skip-mailgun-verification    Skip Mailgun domain verification (faster, manual verify later)
  --dry-run                      Show deployment plan without applying
  --resume-from=<step>           Resume from specific step (1-9)
  --help                         Show this help message

Examples:
  ./deploy-wl.sh afftech
  ./deploy-wl.sh afftech --skip-mailgun-verification
  ./deploy-wl.sh afftech --resume-from=6
  ./deploy-wl.sh afftech --dry-run

Steps:
  1. ACM Certificates
  2. DNS Validation (3-5 min)
  3. CloudFront + S3 (10-15 min)
  4. DNS Records
  5. GitLab Variables
  6. Mailgun Domain
  7. Mailgun DNS
  8. Mailgun Verification (5-10 min)
  9. Final Cleanup

EOF
    exit 0
}

# ============================================================================
# Parse Arguments
# ============================================================================

if [ -z "$WL_NAME" ] || [ "$WL_NAME" == "--help" ]; then
    show_help
fi

shift # Remove wl-name from arguments

for arg in "$@"; do
    case $arg in
        --skip-mailgun-verification)
            SKIP_MAILGUN_VERIFICATION=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --resume-from=*)
            RESUME_FROM="${arg#*=}"
            shift
            ;;
        --help)
            show_help
            ;;
        *)
            print_error "Unknown option: $arg"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# ============================================================================
# Validation
# ============================================================================

CONFIG_FILE="wl-configs/${WL_NAME}.auto.tfvars"

if [ ! -f "$CONFIG_FILE" ]; then
    print_error "Config file not found: $CONFIG_FILE"
    echo ""
    echo "Available configs:"
    ls -1 wl-configs/*.auto.tfvars 2>/dev/null | sed 's/.*\//  - /' || echo "  No configs found"
    exit 1
fi

# Check if .env exists
if [ -f "../../../.env" ]; then
    print_info "Loading environment variables from .env..."
    source ../../../.env
    print_success "Environment loaded"
else
    print_warning ".env file not found. Make sure credentials are set in environment."
fi

# Validate resume step
if ! [[ "$RESUME_FROM" =~ ^[1-9]$ ]]; then
    print_error "Invalid resume step: $RESUME_FROM (must be 1-9)"
    exit 1
fi

# ============================================================================
# Display Configuration
# ============================================================================

print_header "WL Automation Deployment"
echo ""
echo -e "  ${CYAN}WL Name:${NC}                  $WL_NAME"
echo -e "  ${CYAN}Config File:${NC}              $CONFIG_FILE"
echo -e "  ${CYAN}Skip Mailgun Verification:${NC} $SKIP_MAILGUN_VERIFICATION"
echo -e "  ${CYAN}Dry Run:${NC}                  $DRY_RUN"
echo -e "  ${CYAN}Resume From Step:${NC}         $RESUME_FROM"
echo ""

if [ "$DRY_RUN" = true ]; then
    print_warning "DRY RUN MODE - No changes will be applied"
    echo ""
fi

# Confirmation prompt
if [ "$DRY_RUN" = false ]; then
    read -p "$(echo -e ${YELLOW}Continue with deployment? [y/N]:${NC} )" -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Deployment cancelled"
        exit 0
    fi
fi

# ============================================================================
# Terraform Command Builder
# ============================================================================

run_terraform() {
    local targets="$1"
    local description="$2"
    
    if [ "$DRY_RUN" = true ]; then
        print_info "DRY RUN: Would execute:"
        echo "  terraform apply $targets -var-file=\"$CONFIG_FILE\" -auto-approve"
        return 0
    fi
    
    print_info "Executing: $description"
    
    # shellcheck disable=SC2086
    if ! terraform apply $targets -var-file="$CONFIG_FILE" -auto-approve; then
        print_error "Terraform apply failed at: $description"
        echo ""
        print_info "To resume from this step, run:"
        echo "  ./deploy-wl.sh $WL_NAME --resume-from=$CURRENT_STEP"
        exit 1
    fi
}

# ============================================================================
# Track deployment time
# ============================================================================

START_TIME=$(date +%s)
STEP_START_TIME=$START_TIME

step_timer() {
    local step_end=$(date +%s)
    local step_duration=$((step_end - STEP_START_TIME))
    local step_minutes=$((step_duration / 60))
    local step_seconds=$((step_duration % 60))
    
    print_success "Completed in ${step_minutes}m ${step_seconds}s"
    STEP_START_TIME=$(date +%s)
}

# ============================================================================
# Deployment Steps
# ============================================================================

# Step 1: ACM Certificates
CURRENT_STEP=1
if [ $RESUME_FROM -le $CURRENT_STEP ]; then
    print_step "$CURRENT_STEP/9" "Creating ACM Certificates"
    print_info "Creating SSL certificates in eu-central-1 and us-east-1..."
    
    run_terraform \
        "-target='module.main_domain[0].module.acm.aws_acm_certificate.regional[0]' \
         -target='module.main_domain[0].module.acm.aws_acm_certificate.cloudfront[0]'" \
        "ACM Certificates"
    
    step_timer
fi

# Step 2: DNS Validation
CURRENT_STEP=2
if [ $RESUME_FROM -le $CURRENT_STEP ]; then
    print_step "$CURRENT_STEP/9" "DNS Validation"
    print_info "Creating DNS validation records and waiting for AWS validation (3-5 min)..."
    
    run_terraform \
        "-target='module.main_domain[0].module.validation'" \
        "DNS Validation"
    
    step_timer
fi

# Step 3: CloudFront + S3
CURRENT_STEP=3
if [ $RESUME_FROM -le $CURRENT_STEP ]; then
    print_step "$CURRENT_STEP/9" "CloudFront + S3 Distributions"
    print_info "Creating S3 buckets and CloudFront distributions (10-15 min)..."
    print_info "Distributions: admin, agent, cdn, reports"
    
    run_terraform \
        "-target='module.main_domain[0].module.admin' \
         -target='module.main_domain[0].module.agent' \
         -target='module.main_domain[0].module.cdn' \
         -target='module.main_domain[0].module.reports'" \
        "CloudFront Distributions"
    
    step_timer
fi

# Step 4: DNS Records
CURRENT_STEP=4
if [ $RESUME_FROM -le $CURRENT_STEP ]; then
    print_step "$CURRENT_STEP/9" "DNS Records"
    print_info "Creating Cloudflare DNS records..."
    
    run_terraform \
        "-target='module.main_domain[0].cloudflare_dns_record.admin' \
         -target='module.main_domain[0].cloudflare_dns_record.agent' \
         -target='module.main_domain[0].cloudflare_dns_record.cdn' \
         -target='module.main_domain[0].cloudflare_dns_record.reports' \
         -target='module.main_domain[0].cloudflare_dns_record.api'" \
        "DNS Records"
    
    step_timer
fi

# Step 5: GitLab Variables
CURRENT_STEP=5
if [ $RESUME_FROM -le $CURRENT_STEP ]; then
    print_step "$CURRENT_STEP/9" "GitLab CI/CD Variables"
    print_info "Creating GitLab CI/CD variables..."
    
    run_terraform \
        "-target='module.main_domain[0].module.gitlab_variables'" \
        "GitLab Variables"
    
    step_timer
fi

# Step 6: Mailgun Domain
CURRENT_STEP=6
if [ $RESUME_FROM -le $CURRENT_STEP ]; then
    print_step "$CURRENT_STEP/9" "Mailgun Domain"
    print_info "Creating Mailgun domain and SMTP credentials..."
    
    run_terraform \
        "-target='module.main_domain[0].module.mailgun[0].mailgun_domain.wl' \
         -target='module.main_domain[0].module.mailgun[0].random_password.smtp' \
         -target='module.main_domain[0].module.mailgun[0].mailgun_domain_credential.smtp_user'" \
        "Mailgun Domain"
    
    step_timer
fi

# Step 7: Mailgun DNS
CURRENT_STEP=7
if [ $RESUME_FROM -le $CURRENT_STEP ]; then
    print_step "$CURRENT_STEP/9" "Mailgun DNS Records"
    print_info "Creating Mailgun DNS records (MX, TXT/SPF, CNAME/DKIM)..."
    
    run_terraform \
        "-target='module.main_domain[0].module.mailgun[0].cloudflare_dns_record.mailgun_mx' \
         -target='module.main_domain[0].module.mailgun[0].cloudflare_dns_record.mailgun_txt' \
         -target='module.main_domain[0].module.mailgun[0].cloudflare_dns_record.mailgun_cname'" \
        "Mailgun DNS Records"
    
    step_timer
fi

# Step 8: Mailgun Verification
CURRENT_STEP=8
if [ $RESUME_FROM -le $CURRENT_STEP ]; then
    if [ "$SKIP_MAILGUN_VERIFICATION" = false ]; then
        print_step "$CURRENT_STEP/9" "Mailgun Domain Verification"
        print_info "Verifying Mailgun domain (5-10 min)..."
        print_warning "This may take up to 10 minutes. Press Ctrl+C to skip and verify manually later."
        
        run_terraform \
            "-target='module.main_domain[0].module.mailgun[0].mailgun_domain_verification.wl'" \
            "Mailgun Verification"
        
        step_timer
    else
        print_step "$CURRENT_STEP/9" "Mailgun Domain Verification"
        print_warning "SKIPPED - You can verify manually at https://app.mailgun.com/app/sending/domains"
        print_info "Or run: terraform apply -target='module.main_domain[0].module.mailgun[0].mailgun_domain_verification.wl' -auto-approve"
    fi
fi

# Step 9: Final Cleanup
CURRENT_STEP=9
if [ $RESUME_FROM -le $CURRENT_STEP ]; then
    print_step "$CURRENT_STEP/9" "Final Cleanup"
    print_info "Running final apply to ensure all resources are synchronized..."
    
    run_terraform "" "Final Apply"
    
    step_timer
fi

# ============================================================================
# Deployment Complete
# ============================================================================

if [ "$DRY_RUN" = false ]; then
    END_TIME=$(date +%s)
    TOTAL_DURATION=$((END_TIME - START_TIME))
    TOTAL_MINUTES=$((TOTAL_DURATION / 60))
    TOTAL_SECONDS=$((TOTAL_DURATION % 60))
    
    print_header "Deployment Complete! 🎉"
    echo ""
    print_success "Total deployment time: ${TOTAL_MINUTES}m ${TOTAL_SECONDS}s"
    echo ""
    
    # Display summary
    echo -e "${CYAN}📊 Deployment Summary${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Extract domain info
    DOMAIN_INFO=$(terraform output -json 2>/dev/null | jq -r '.main_domain_summary.value // empty')
    
    if [ -n "$DOMAIN_INFO" ]; then
        DOMAIN=$(echo "$DOMAIN_INFO" | jq -r '.domain')
        ADMIN_FQDN=$(echo "$DOMAIN_INFO" | jq -r '.admin.fqdn')
        AGENT_FQDN=$(echo "$DOMAIN_INFO" | jq -r '.agent.fqdn')
        CDN_FQDN=$(echo "$DOMAIN_INFO" | jq -r '.cdn.fqdn')
        REPORTS_FQDN=$(echo "$DOMAIN_INFO" | jq -r '.reports.fqdn')
        API_FQDN=$(echo "$DOMAIN_INFO" | jq -r '.api_dns.fqdn')
        
        echo ""
        echo -e "  ${GREEN}Domain:${NC}   $DOMAIN"
        echo ""
        echo -e "  ${CYAN}🔗 URLs:${NC}"
        echo -e "    Admin:   https://$ADMIN_FQDN"
        echo -e "    Agent:   https://$AGENT_FQDN"
        echo -e "    CDN:     https://$CDN_FQDN"
        echo -e "    Reports: https://$REPORTS_FQDN"
        echo -e "    API:     https://$API_FQDN"
        
        # Mailgun info
        MAILGUN_INFO=$(echo "$DOMAIN_INFO" | jq -r '.mailgun // empty')
        if [ -n "$MAILGUN_INFO" ]; then
            SMTP_LOGIN=$(echo "$MAILGUN_INFO" | jq -r '.smtp_login')
            
            echo ""
            echo -e "  ${CYAN}📧 Mailgun (EU):${NC}"
            echo -e "    SMTP Login: $SMTP_LOGIN"
            echo -e "    SMTP Password: ${YELLOW}[SENSITIVE]${NC}"
            echo -e "    ${BLUE}To view password:${NC}"
            echo -e "      terraform output -json | jq -r '.main_domain_summary.value.mailgun.smtp_password'"
        fi
    fi
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Next steps
    echo -e "${CYAN}📝 Next Steps:${NC}"
    echo -e "  1. Verify CloudFront distributions are deployed (10-15 min)"
    echo -e "  2. Test URLs above"
    echo -e "  3. Check GitLab CI/CD variables"
    if [ "$SKIP_MAILGUN_VERIFICATION" = true ]; then
        echo -e "  4. ${YELLOW}Verify Mailgun domain manually${NC} at:"
        echo -e "     https://app.mailgun.com/app/sending/domains"
    else
        echo -e "  4. Test email sending via SMTP"
    fi
    echo ""
    
else
    print_header "Dry Run Complete"
    print_info "No changes were applied. Remove --dry-run to deploy."
fi

# ============================================================================
# Error Log Check
# ============================================================================

if [ -f "terraform.log" ]; then
    if grep -q "Error" terraform.log; then
        print_warning "Errors detected in terraform.log. Review the file for details."
    fi
fi

print_success "Script finished successfully! 🚀"