# Azure Attack Path Demo – Cortex Cloud

## 📌 Cel
Ten projekt Terraform służy **wyłącznie do celów testowych i demonstracyjnych**.  
Celem jest pokazanie **attack path** w środowisku Azure – od zasobów infrastrukturalnych (VM, sieć, potencjalnie Storage) aż do widoczności i korelacji w **Cortex Cloud**.

Projekt **nie jest wzorcem produkcyjnym**

---

## 🧪 Zakres scenariusza demo

Środowisko tworzy:

- **Ubuntu Linux VM**
  - publiczny adres IP
  - dostęp SSH oparty o klucz
  - pełni rolę **entry point / jump host**
- **Windows Server VM**
  - brak publicznego IP
  - dostępna tylko z tej samej podsieci
  - typowy przykład zasobu „wewnętrznego”
- **Wspólna sieć prywatna (VNet + Subnet)**
- **NSG** pokazujące podstawowe założenia segmentacji

Scenariusz demo zakłada możliwość:
- wejścia przez publicznie dostępny zasób (Linux VM),
- poruszania się lateralnie w sieci prywatnej,
- pokazania **attack path / blast radius** w Cortex Cloud.

---

## ☁️ Cortex Cloud

Środowisko jest przygotowane pod:
- instalację **Cortex Cloud / Cortex XDR / Runtime Security Agent**:
  - Linux: instalator `.sh` (cloud-init / custom script)
  - Windows: instalator `.msi` (VM Extension)

Dzięki temu możliwe jest:
- mapowanie relacji między zasobami Azure,
- korelacja zdarzeń hostowych i cloudowych,
- wizualizacja **attack paths** w Cortex Cloud UI.

> ⚠️ Instalacja agenta nie jest elementem „core” tego repo – może być dołączona opcjonalnie w zależności od scenariusza demo.

---

## 🔐 Bezpieczeństwo i ograniczenia

- Klucze SSH:
  - generowane **poza Terraformem** (Azure Portal / CLI / lokalnie),
  - Terraform używa **wyłącznie klucza publicznego**.
- Hasła Windows:
  - generowane losowo,
  - oznaczone jako `sensitive`.
- Środowisko **nie jest hardened**:
  - reguły NSG są uproszczone,
  - publiczny SSH służy tylko do demonstracji attack surface.

---

## 🚫 Czego ten projekt NIE jest

- ❌ produkcyjną referencją bezpieczeństwa
- ❌ wzorcem architektury Zero Trust
- ❌ pełnym landing zone Azure

---

## 🧠 Przykładowe use-case’y demo

- Attack Path visualization (VM → VM → inne zasoby)
- Cloud posture + workload security
- Lateral movement detection
- Demonstracja wartości Cortex Cloud dla zespołów:
  - SecOps
  - Cloud Security
  - Red / Purple Team

---

## 🗑️ Sprzątanie

Po zakończeniu testów:
```bash
terraform destroy
