# Mailgun Module

Bu modul WL Automation sistemində Mailgun email dəstəyini tam avtomatlaşdırır.

## ✨ Xüsusiyyətlər

### ✅ Avtomatlaşdırılan Proseslər

1. **Mailgun Domain Yaradılması**
   - `use_automatic_sender_security = true` ilə avtomatik SPF/DKIM alignment
   - EU region dəstəyi
   - Spam filtering konfiqurasiyası

2. **SMTP Credential Yaradılması**
   - Random password generasiya olunur (16 simvol)
   - Avtomatik `postmaster@support.domain.com` email yaradır
   - Password Terraform state-də encrypted saxlanır

3. **DNS Records (Cloudflare)**
   - **MX Records**: Email qəbul etmək üçün
   - **TXT/SPF Records**: Email göndərmək üçün
   - **CNAME/DKIM Records**: Email authentication üçün
   - Hamısı avtomatik Cloudflare-ə yazılır

4. **Domain Verification** 🎉
   - DNS records əlavə edildikdən sonra avtomatik verification başlayır
   - 15 saniyə interval ilə polling (default)
   - Maksimum 10 dəqiqə gözləyir (default)
   - **Manual "Verify" düyməsinə klikləməyə ehtiyac yoxdur!**

## 📋 İstifadə

### Minimal Nümunə

```hcl
module "mailgun" {
  source = "./modules/mailgun"
  
  domain             = "afftech.xyz"
  mail_domain        = "support.afftech.xyz"
  cloudflare_zone_id = "84787ea66aa226406e7c736892c6d493"
}
```

### Tam Nümunə

```hcl
module "mailgun" {
  source = "./modules/mailgun"
  
  domain             = "afftech.xyz"
  mail_domain        = "support.afftech.xyz"
  mailgun_region     = "eu"
  cloudflare_zone_id = "84787ea66aa226406e7c736892c6d493"
  smtp_login         = "postmaster"
  
  # Verification settings
  wait_for_verification       = true
  verification_poll_interval  = "15s"
  verification_timeout        = "10m"
  
  tags = {
    Project = "WL-Automation"
    Purpose = "Email Support"
  }
}
```

## 🔑 Tələb Olunan Environment Variables

```bash
export TF_VAR_mailgun_api_key="your-mailgun-api-key-here"
```

Və ya `terraform.tfvars` (git-ə commit etməyin!):

```hcl
mailgun_api_key = "your-mailgun-api-key-here"
```

## 📤 Outputs

```hcl
output "mailgun_smtp_login" {
  value = module.mailgun.smtp_login
}

output "mailgun_smtp_password" {
  value     = module.mailgun.smtp_password
  sensitive = true
}

output "mailgun_verification_status" {
  value = module.mailgun.verification_status
}
```

## 🎯 WL Konfiqurasiya

WL config file-ında (`wl-configs/domain.auto.tfvars`):

```hcl
domain             = "afftech.xyz"
wl_type            = "agent"
platform_code      = "AFFTECH"
cloudflare_zone_id = "84787ea66aa226406e7c736892c6d493"

# ✅ Mailgun əlavə edin:
mail_domain = "support.afftech.xyz"
```

## 🚀 Deployment

```bash
# 1. Mailgun API key set edin
export TF_VAR_mailgun_api_key="your-api-key"

# 2. Terraform init
cd terraform/environments/prod
terraform init -upgrade

# 3. Plan yoxlayın
terraform plan -var-file="wl-configs/afftech.auto.tfvars"

# 4. Apply edin
terraform apply -var-file="wl-configs/afftech.auto.tfvars"
```

## 📊 Yaradılan Resurslar

| Resource | Nümunə | Məqsəd |
|----------|--------|---------|
| **Mailgun Domain** | `support.afftech.xyz` | Email domain |
| **SMTP Credential** | `postmaster@support.afftech.xyz` | SMTP authentication |
| **MX Records** | `mxa.eu.mailgun.org` (priority 10) | Email receiving |
| **TXT Record** | `v=spf1 include:mailgun.org ~all` | SPF validation |
| **CNAME Records** | `pdk1._domainkey...` | DKIM keys |
| **Domain Verification** | Status: `active` | Avtomatik verification |

## ⚙️ Variables

| Variable | Növ | Default | Açıqlama |
|----------|-----|---------|----------|
| `domain` | string | - | **Required**. Main domain |
| `mail_domain` | string | - | **Required**. Mail domain |
| `mailgun_region` | string | `"eu"` | Mailgun region (us/eu) |
| `cloudflare_zone_id` | string | - | **Required**. Cloudflare Zone ID |
| `smtp_login` | string | `"postmaster"` | SMTP username |
| `wait_for_verification` | bool | `true` | Verification gözləsin? |
| `verification_poll_interval` | string | `"15s"` | Polling interval |
| `verification_timeout` | string | `"10m"` | Maximum gözləmə vaxtı |

## 🔍 Troubleshooting

### Verification Uğursuz Olarsa

1. **DNS propagation yoxlayın:**
   ```bash
   dig MX support.afftech.xyz
   dig TXT support.afftech.xyz
   dig CNAME pdk1._domainkey.support.afftech.xyz
   ```

2. **Mailgun UI-da yoxlayın:**
   - https://app.eu.mailgun.com/mg/sending/domains
   - Domain seçin
   - "Domain verification & DNS" tab-a baxın

3. **Timeout artırın:**
   ```hcl
   verification_timeout = "20m"  # 10m əvəzinə 20m
   ```

### Provider Error

Əgər `mailgun_domain_verification` resource tapılmasa:

```bash
# Provider binary-ni yoxlayın
ls -la ~/.terraform.d/plugins/registry.terraform.io/murad-heydarov/mailgun/0.1.0/darwin_arm64/

# Yenidən init edin
terraform init -upgrade
```

## 📝 Notes

- **Automatic Sender Security** hər zaman enabled-dir (`use_automatic_sender_security = true`)
- **SMTP password** Terraform state-də encrypted saxlanır
- **DNS records** avtomatik Cloudflare-ə yazılır
- **Verification** DNS propagation-dan sonra 5-10 dəqiqə içində tamamlanır
- **EU region** default olaraq istifadə olunur

## 🔗 Əlaqəli Modullar

- `acm-certificates` - SSL certificate yaradır
- `acm-dns-validation` - SSL validation edir
- `wl-domain` - Mailgun-u çağırır

## 📚 References

- [Mailgun API Documentation](https://documentation.mailgun.com/en/latest/api_reference.html)
- [Mailgun Domain Verification](https://help.mailgun.com/hc/en-us/articles/32884702360603-Domain-Verification-Setup-Guide)
- [Custom Provider GitHub](https://github.com/murad-heydarov/terraform-provider-mailgun)

