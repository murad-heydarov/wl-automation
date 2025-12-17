#!/bin/bash
# deploy-wl-step-by-step.sh
# Manual step-by-step WL deployment with detailed control

set -e

# ============================================================================
# Configuration
# ============================================================================
WL_NAME="${1:-afftech}"
CONFIG_FILE="wl-configs/${WL_NAME}.auto.tfvars"

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

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

# ============================================================================
# Validation
# ============================================================================

if [ ! -f "$CONFIG_FILE" ]; then
    print_error "Config file not found: $CONFIG_FILE"
    echo ""
    echo "Available configs:"
    ls -1 wl-configs/*.auto.tfvars 2>/dev/null | sed 's/.*\//  - /' || echo "  No configs found"
    exit 1
fi

# ============================================================================
# Start Deployment
# ============================================================================

print_header "WL Automation - Step-by-Step Deployment"
echo ""
echo -e "  ${CYAN}WL Name:${NC}      $WL_NAME"
echo -e "  ${CYAN}Config File:${NC}  $CONFIG_FILE"
echo ""

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
# STEP 1: ACM Certificates
# ============================================================================
print_step "1/9" "Creating ACM Certificates"
print_info "Creating SSL certificates in eu-central-1 and us-east-1..."

terraform apply \
    -target='module.main_domain[0].module.acm.aws_acm_certificate.regional[0]' \
    -target='module.main_domain[0].module.acm.aws_acm_certificate.cloudfront[0]' \
    -var-file="$CONFIG_FILE" \
    -auto-approve

step_timer

# ============================================================================
# STEP 2: DNS Validation
# ============================================================================
print_step "2/9" "DNS Validation"
print_info "Creating DNS validation records and waiting for AWS validation (3-5 min)..."

terraform apply \
    -target='module.main_domain[0].module.validation' \
    -var-file="$CONFIG_FILE" \
    -auto-approve

step_timer

# ============================================================================
# STEP 3: CloudFront + S3
# ============================================================================
print_step "3/9" "CloudFront + S3 Distributions"
print_info "Creating S3 buckets and CloudFront distributions (10-15 min)..."
print_info "Distributions: admin, agent, cdn, reports"

terraform apply \
    -target='module.main_domain[0].module.admin' \
    -target='module.main_domain[0].module.agent' \
    -target='module.main_domain[0].module.cdn' \
    -target='module.main_domain[0].module.reports' \
    -var-file="$CONFIG_FILE" \
    -auto-approve

step_timer

# ============================================================================
# STEP 4: DNS Records
# ============================================================================
print_step "4/9" "DNS Records"
print_info "Creating Cloudflare DNS records..."

terraform apply \
    -target='module.main_domain[0].cloudflare_dns_record.admin' \
    -target='module.main_domain[0].cloudflare_dns_record.agent' \
    -target='module.main_domain[0].cloudflare_dns_record.cdn' \
    -target='module.main_domain[0].cloudflare_dns_record.reports' \
    -target='module.main_domain[0].cloudflare_dns_record.api' \
    -var-file="$CONFIG_FILE" \
    -auto-approve

step_timer

# ============================================================================
# STEP 5: GitLab Variables
# ============================================================================
print_step "5/9" "GitLab CI/CD Variables"
print_info "Creating GitLab CI/CD variables..."

terraform apply \
    -target='module.main_domain[0].module.gitlab_variables' \
    -var-file="$CONFIG_FILE" \
    -auto-approve

step_timer

# ============================================================================
# STEP 6: Mailgun Domain
# ============================================================================
print_step "6/9" "Mailgun Domain"
print_info "Creating Mailgun domain and SMTP credentials..."

terraform apply \
    -target='module.main_domain[0].module.mailgun[0].mailgun_domain.wl' \
    -target='module.main_domain[0].module.mailgun[0].random_password.smtp' \
    -target='module.main_domain[0].module.mailgun[0].mailgun_domain_credential.smtp_user' \
    -var-file="$CONFIG_FILE" \
    -auto-approve

step_timer

# ============================================================================
# STEP 7: Mailgun DNS
# ============================================================================
print_step "7/9" "Mailgun DNS Records"
print_info "Creating Mailgun DNS records (MX, TXT/SPF, CNAME/DKIM)..."

terraform apply \
    -target='module.main_domain[0].module.mailgun[0].cloudflare_dns_record.mailgun_mx' \
    -target='module.main_domain[0].module.mailgun[0].cloudflare_dns_record.mailgun_txt' \
    -target='module.main_domain[0].module.mailgun[0].cloudflare_dns_record.mailgun_cname' \
    -var-file="$CONFIG_FILE" \
    -auto-approve

step_timer

# ============================================================================
# STEP 8: Mailgun Verification
# ============================================================================
print_step "8/9" "Mailgun Domain Verification"
print_info "Verifying Mailgun domain (2-5 min with v0.1.6 provider)..."
print_info "Provider will re-check DNS every 30 seconds for up to 20 minutes"

terraform apply \
    -target='module.main_domain[0].module.mailgun[0].mailgun_domain_verification.wl' \
    -var-file="$CONFIG_FILE" \
    -auto-approve

step_timer

# ============================================================================
# STEP 9: Final Cleanup
# ============================================================================
print_step "9/9" "Final Cleanup"
print_info "Running final apply to ensure all resources are synchronized..."

terraform apply -var-file="$CONFIG_FILE" -auto-approve

step_timer

# ============================================================================
# Deployment Complete
# ============================================================================

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
echo -e "  4. Test email sending via SMTP"
echo ""

print_success "Script finished successfully! 🚀"