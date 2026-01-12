#!/bin/bash
# -------------------------------------------------------------------------
# Projeto: Monitor de Saúde do Sistema (SRE Hardened Version)
# Arquivo: monitor.sh
# Descrição: Versão com tratamento de erros, validação de dependências
#            e logs de falha separados.
#
# Autor: Arthur O2B Team
# -------------------------------------------------------------------------


set -u  # Erro se usar variável não declarada
set -o pipefail # Erro se qualquer parte de um pipe falhar

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="$BASE_DIR/configs/config.env"
ERROR_LOG="$BASE_DIR/logs/error.log"

log_error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERRO: $1" >> "$ERROR_LOG"
}

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "CRITICAL: Configuração não encontrada." >&2
    exit 1
fi

for cmd in git df free uptime hostname; do
    if ! command -v $cmd &> /dev/null; then
        log_error "Comando obrigatório '$cmd' não encontrado. Abortando."
        exit 1
    fi
done

ANO_ATUAL=$(date +'%Y')
MES_ATUAL=$(date +'%m')
DIA_ATUAL=$(date +'%Y-%m-%d')
HORA_ATUAL=$(date +'%H:%M:%S')

LOG_PATH="$BASE_DIR/logs/$ANO_ATUAL/$MES_ATUAL"
mkdir -p "$LOG_PATH" || { log_error "Falha ao criar diretório $LOG_PATH"; exit 1; }

ARQUIVO_LOG="$LOG_PATH/monitor_$DIA_ATUAL.log"

(
    echo "======================================================================"
    echo "RELATÓRIO: $PROJECT_NAME ($ENV_TYPE)"
    echo "Data: $DIA_ATUAL | Hora: $HORA_ATUAL"
    echo "Hostname: $(hostname)"
    echo "======================================================================"
    echo ""

    # CPU
    if [ "${ENABLE_CPU_STATS:-false}" = "true" ]; then
        echo "=== [CPU] ==="
        uptime | awk -F'load average:' '{ print "Load Average:" $2 }' | xargs
        top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{print "Uso: " $2 "% user, " $4 "% system, " $8 "% idle"}' || echo "Detalhes de CPU indisponíveis via Top."
        echo ""
    fi

    if [ "${ENABLE_MEM_STATS:-false}" = "true" ]; then
        echo "=== [MEMÓRIA] ==="
        free -h | grep -E "Mem|Swap" || echo "Erro ao ler memória."
        echo ""
    fi

    if [ "${ENABLE_DISK_STATS:-false}" = "true" ]; then
        echo "=== [DISCO] ==="
        df -h --output=source,size,used,avail,pcent,target -x tmpfs -x devtmpfs -x loop || echo "Erro ao ler disco."
        echo ""
    fi

    if [ "${ENABLE_TEMP_STATS:-false}" = "true" ]; then
        echo "=== [TEMPERATURA] ==="
        if [ -d "/sys/class/thermal/thermal_zone0" ]; then
             TEMP=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
             if [ -n "$TEMP" ]; then
                echo "CPU Zone0: $(awk "BEGIN {printf \"%.1f\", $TEMP/1000}")°C"
             else
                echo "Erro leitura sensor."
             fi
        else
             echo "Sensores não disponíveis."
        fi
        echo ""
    fi

    echo "----------------------------------------------------------------------"
    echo "Fim da execução: $HORA_ATUAL"
    echo "----------------------------------------------------------------------"
    echo ""

) >> "$ARQUIVO_LOG" 2>> "$ERROR_LOG"

chmod 640 "$ARQUIVO_LOG"

cd "$BASE_DIR" || { log_error "Falha ao acessar $BASE_DIR para git sync"; exit 1; }

git add logs/

if ! git diff-index --quiet HEAD; then
    if git commit -m "chore(logs): auto-report $DIA_ATUAL [automated]"; then
        if command -v timeout &> /dev/null; then
            PUSH_CMD="timeout 30s git push origin main"
        else
            PUSH_CMD="git push origin main"
        fi

        if ! eval $PUSH_CMD > /dev/null 2>&1; then
            log_error "Falha no git push (Rede ou Permissão SSH)."
        fi
    else
        log_error "Falha ao realizar git commit."
    fi
fi
