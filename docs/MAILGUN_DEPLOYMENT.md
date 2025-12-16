# Mailgun Deployment Guide

Bu sənəd WL Automation sistemində Mailgun inteqrasiyasının deployment addımlarını izah edir.

## 🎯 Məqsəd

Manual olaraq Mailgun-da domain yaratmaq, SMTP user yaratmaq, DNS records əlavə etmək və verify etmək əvəzinə, **Terraform bütün bu prosesləri avtomatlaşdırır**.

## ✅ Hazırlıq

### 1. Mailgun Provider Binary

Provider artıq compile olunub və aşağıdakı yerdə olmalıdır:

```bash
~/.terraform.d/plugins/registry.terraform.io/murad-heydarov/mailgun/0.1.0/darwin_arm64/terraform-provider-mailgun
```

Əgər yoxdursa:

```bash
cd ~/Desktop/projects/gr/terraform-mailgun-provider
go build -o terraform-provider-mailgun
mkdir -p ~/.terraform.d/plugins/registry.terraform.io/murad-heydarov/mailgun/0.1.0/darwin_arm64/
cp terraform-provider-mailgun ~/.terraform.d/plugins/registry.terraform.io/murad-heydarov/mailgun/0.1.0/darwin_arm64/
chmod +x ~/.terraform.d/plugins/registry.terraform.io/murad-heydarov/mailgun/0.1.0/darwin_arm64/terraform-provider-mailgun
```

### 2. Mailgun API Key

Mailgun account-dan API key alın:

1. https://app.eu.mailgun.com/mg/account/security/api_keys
2. "Private API key" kopyalayın
3. Environment variable olaraq set edin:

```bash
export TF_VAR_mailgun_api_key="key-your-mailgun-api-key-here"
```

**Və ya** `terraform.tfvars` yaradın (git-ə commit etməyin!):

```bash
cd ~/Desktop/projects/gr/wl-automation/terraform/environments/prod
cat > terraform.tfvars <<EOF
mailgun_api_key      = "key-your-mailgun-api-key-here"
cloudflare_api_token = "your-cloudflare-token"
gitlab_token         = "your-gitlab-token"
EOF
```

`.gitignore`-də `terraform.tfvars` artıq var, commit olunmayacaq.

## 🚀 Deployment Addımları

### Addım 1: WL Config Hazırlayın

Yeni WL üçün config yaradın:

```bash
cd ~/Desktop/projects/gr/wl-automation/terraform/environments/prod/wl-configs

# Template-dən kopyalayın (agent WL nümunəsi)
cp templates/agent-wl.auto.tfvars.template newdomain.auto.tfvars

# Edit edin
vim newdomain.auto.tfvars
```

**Mailgun-u aktiv etmək üçün bu sətri əlavə edin:**

```hcl
domain              = "newdomain.com"
wl_type             = "agent"
platform_code       = "NEWDOM"
cloudflare_zone_id  = "your-zone-id"

# ✅ Mailgun Configuration
mail_domain = "support.newdomain.com"

# ... digər konfiqlərdən sonra ...
```

### Addım 2: Terraform Init

```bash
cd ~/Desktop/projects/gr/wl-automation/terraform/environments/prod

# Provider-i yükləmək üçün init edin
terraform init -upgrade
```

**Gözlənilən output:**

```
Initializing provider plugins...
- Finding murad-heydarov/mailgun versions matching "0.1.0"...
- Installing murad-heydarov/mailgun v0.1.0...
- Installed murad-heydarov/mailgun v0.1.0 (unauthenticated)
```

### Addım 3: Plan Yoxlayın

```bash
terraform plan -var-file="wl-configs/newdomain.auto.tfvars"
```

**Mailgun resources-də axtarın:**

```
Plan: XX to add, 0 to change, 0 to destroy.

...
# module.main_domain[0].module.mailgun[0].mailgun_domain.wl will be created
  + resource "mailgun_domain" "wl" {
      + name                         = "support.newdomain.com"
      + region                       = "eu"
      + use_automatic_sender_security = true
      ...
    }

# module.main_domain[0].module.mailgun[0].mailgun_domain_credential.smtp_user will be created
  + resource "mailgun_domain_credential" "smtp_user" {
      + domain   = "support.newdomain.com"
      + login    = "postmaster"
      + password = (sensitive value)
      ...
    }

# module.main_domain[0].module.mailgun[0].mailgun_domain_verification.wl will be created
  + resource "mailgun_domain_verification" "wl" {
      + domain          = "support.newdomain.com"
      + wait_for_active = true
      ...
    }
```

### Addım 4: Apply

```bash
terraform apply -var-file="wl-configs/newdomain.auto.tfvars"
```

**Nə baş verir:**

1. **Mailgun domain yaradılır** (~5 saniyə)
2. **SMTP credential yaradılır** (~2 saniyə)
3. **DNS records Cloudflare-ə yazılır** (~10-15 saniyə)
4. **Domain verification başlayır** (5-10 dəqiqə)
   - Hər 15 saniyədə bir Mailgun-u yoxlayır
   - DNS records valid olana qədər gözləyir
   - `status = "active"` olana qədər davam edir

**Verification zamanı görsənəcək output:**

```
module.main_domain[0].module.mailgun[0].mailgun_domain_verification.wl: Creating...
module.main_domain[0].module.mailgun[0].mailgun_domain_verification.wl: Still creating... [15s elapsed]
module.main_domain[0].module.mailgun[0].mailgun_domain_verification.wl: Still creating... [30s elapsed]
...
module.main_domain[0].module.mailgun[0].mailgun_domain_verification.wl: Creation complete after 3m42s
```

### Addım 5: Verification Yoxlayın

Apply tamamlandıqdan sonra:

```bash
# Output-da SMTP credentials-i görün
terraform output -json | jq '.main_domain_summary.value.mailgun'

# Və ya Mailgun UI-da yoxlayın
open https://app.eu.mailgun.com/mg/sending/domains
```

**Gözlənilən status:** `Verified` (yaşıl)

## 📊 Yaradılan Resources

### Mailgun

| Resource | Nümunə |
|----------|--------|
| Domain | `support.newdomain.com` |
| SMTP User | `postmaster@support.newdomain.com` |
| SMTP Password | `(random 16 chars)` |
| Region | `eu` |
| Status | `active` |

### Cloudflare DNS

| Type | Name | Content |
|------|------|---------|
| MX | `support.newdomain.com` | `mxa.eu.mailgun.org` (priority 10) |
| MX | `support.newdomain.com` | `mxb.eu.mailgun.org` (priority 10) |
| TXT | `support.newdomain.com` | `v=spf1 include:mailgun.org ~all` |
| CNAME | `pdk1._domainkey.support.newdomain.com` | `pdk1._domainkey.xxx.dkim1.eu.mgsend.org` |
| CNAME | `pdk2._domainkey.support.newdomain.com` | `pdk2._domainkey.xxx.dkim1.eu.mgsend.org` |
| CNAME | `email.support.newdomain.com` | `eu.mailgun.org` |

## 🔍 Troubleshooting

### Problem: Verification timeout

**Error:**
```
Error: timeout while waiting for domain verification
```

**Həll:**

1. DNS propagation yoxlayın:
   ```bash
   dig MX support.newdomain.com
   dig TXT support.newdomain.com
   ```

2. Cloudflare-də records-u yoxlayın:
   - https://dash.cloudflare.com

3. Timeout artırın:
   ```hcl
   # wl-domain/main.tf-də
   module "mailgun" {
     verification_timeout = "20m"  # 10m-dən artır
   }
   ```

4. Yenidən apply edin:
   ```bash
   terraform apply -var-file="wl-configs/newdomain.auto.tfvars"
   ```

### Problem: Provider not found

**Error:**
```
Error: Failed to query available provider packages
```

**Həll:**

```bash
# Provider binary-ni yoxlayın
ls -la ~/.terraform.d/plugins/registry.terraform.io/murad-heydarov/mailgun/0.1.0/darwin_arm64/

# Yenidən build və install edin
cd ~/Desktop/projects/gr/terraform-mailgun-provider
go build -o terraform-provider-mailgun
cp terraform-provider-mailgun ~/.terraform.d/plugins/registry.terraform.io/murad-heydarov/mailgun/0.1.0/darwin_arm64/

# Terraform init
cd ~/Desktop/projects/gr/wl-automation/terraform/environments/prod
rm -rf .terraform .terraform.lock.hcl
terraform init
```

### Problem: DNS records düzgün deyil

**Error:**
```
Error: sending_dns_records shows invalid
```

**Həll:**

1. Cloudflare-də proxy disabled olduğunu yoxlayın:
   - Mailgun DNS records üçün **Proxy OFF** olmalıdır
   - Yalnız API record-u üçün proxy ON

2. TTL 1 olduğunu yoxlayın

3. Manual olaraq düzəldin və terraform import edin:
   ```bash
   terraform import 'module.main_domain[0].module.mailgun[0].cloudflare_dns_record.mailgun_mx["id"]' zone_id/record_id
   ```

## 📋 Checklist

Deployment-dan əvvəl:

- [ ] Mailgun API key hazırdır
- [ ] Provider binary installed
- [ ] WL config-də `mail_domain` set olunub
- [ ] Cloudflare zone ID düzgündür
- [ ] `.gitignore`-də `terraform.tfvars` var

Deployment-dan sonra:

- [ ] Mailgun UI-da domain `Verified` statusundadır
- [ ] SMTP credentials outputs-da görünür
- [ ] Cloudflare-də bütün DNS records yaradılıb
- [ ] Test email göndərmək mümkündür

## 🧪 Test Email

Deployment-dan sonra test email göndərin:

```bash
# SMTP credentials-i alın
SMTP_LOGIN=$(terraform output -raw main_domain_summary | jq -r '.mailgun.smtp_login')
SMTP_PASSWORD=$(terraform output -raw main_domain_summary | jq -r '.mailgun.smtp_password')

# Test email (curl ilə)
curl -s --user "api:$TF_VAR_mailgun_api_key" \
  https://api.eu.mailgun.net/v3/support.newdomain.com/messages \
  -F from="Test <postmaster@support.newdomain.com>" \
  -F to="your-email@example.com" \
  -F subject="Test Email from WL Automation" \
  -F text="This is a test email sent via Mailgun API."
```

## 📚 Əlavə Resources

- [Mailgun Module README](../terraform/modules/mailgun/README.md)
- [WL Automation Main README](../README.md)
- [Terraform Provider Source](https://github.com/murad-heydarov/terraform-provider-mailgun)
- [Mailgun Documentation](https://documentation.mailgun.com)

## 🆘 Kömək

Problemlərlə qarşılaşsanız:

1. Provider logs yoxlayın:
   ```bash
   TF_LOG=DEBUG terraform apply
   ```

2. Mailgun API-ni manual test edin:
   ```bash
   curl -s --user "api:$TF_VAR_mailgun_api_key" \
     https://api.eu.mailgun.net/v4/domains/support.newdomain.com
   ```

3. GitHub issues yaradın:
   - https://github.com/murad-heydarov/terraform-provider-mailgun/issues

