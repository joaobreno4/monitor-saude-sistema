# 🏥 Monitor de Saúde do Sistema (Linux/Debian)

Sistema de observabilidade e backup automatizado para servidores Linux Debian.
Coleta métricas vitais (CPU, RAM, Disco, Temperatura), gera logs auditáveis e sincroniza automaticamente com repositório remoto via Git.

---

## 🚀 Funcionalidades

* **Coleta Abrangente:** Monitora Load Average, Uso de Memória, Partições de Disco e Sensores Térmicos.
* **Automação:** Execução diária via Cron (sem intervenção humana).
* **Auto-Healing:** Recria estrutura de diretórios e arquivos se deletados acidentalmente.
* **Hardening:** Permissões restritas (`700`/`600`) seguindo o princípio do menor privilégio.
* **Git Sync:** Versionamento automático dos logs para backup offsite (GitHub/GitLab).
* **Fail-Safe:** Tratamento de erros de rede e execução, com logs de falha dedicados.

---

## 📂 Estrutura do Projeto

\`\`\`text
monitor-saude-sistema/
├── configs/
│   └── config.env       # Configurações globais (NÃO COMITAR SEGREDOS AQUI)
├── logs/
│   ├── YYYY/MM/         # Logs organizados hierarquicamente
│   ├── error.log        # Registro de falhas críticas
│   └── cron_launcher.log # Logs de execução do agendador
├── scripts/
│   └── monitor.sh       # Script principal (Engine)
└── README.md            # Esta documentação
\`\`\`

## ⚙️ Instalação e Configuração

### 1. Pré-requisitos
* Linux Debian/Ubuntu
* Git configurado com chaves SSH
* Pacotes: `coreutils`, `lm-sensors` (opcional)

### 2. Configuração do Cron
O sistema roda automaticamente às 09:00 AM.
Para verificar ou instalar:

\`\`\`bash
# Verifique se o job existe
crontab -l

# Exemplo de entrada (Caminhos absolutos são obrigatórios):
0 9 * * * /usr/bin/bash /home/usuario/monitor-saude-sistema/scripts/monitor.sh >> /home/usuario/monitor-saude-sistema/logs/cron_launcher.log 2>&1
\`\`\`

## 🛡️ Segurança (Hardening)

As permissões foram endurecidas para evitar execução não autorizada:

* `scripts/monitor.sh`: **700** (Apenas dono executa)
* `configs/config.env`: **600** (Apenas dono lê)
* `.git/`: **700** (Proteção do histórico)

## 🆘 Disaster Recovery (Restauração)

Se o servidor for perdido, os logs estão salvos no GitHub. Para restaurar em um novo servidor:

1.  Clone o repositório:
    \`git clone git@github.com:seu-usuario/monitor-saude-sistema.git\`
2.  Restaure as permissões de segurança:
    \`chmod 700 scripts/monitor.sh && chmod 600 configs/config.env\`
3.  Reconfigure o Cron (ver seção acima).

---

**Status do Projeto:** ✅ Estável / Produção
**Mantenedor:** Equipe DevOps O2B
