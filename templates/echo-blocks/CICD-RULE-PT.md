<!-- CICD-RULE:repodocs -->

## CI — o runner self-hosted da frota está aberto a qualquer repositório

> Eco marcado. A fonte única é **[samirhvbr/repodocs](https://github.com/samirhvbr/repodocs/blob/master/docs/ci.md)**
> — mude lá, não aqui. Este bloco é regenerado.

**A frota tem uma máquina de CI, a `cicd`: um runner self-hosted do GitHub
Actions que não gasta os minutos hospedados da conta.** Ela existe porque esse
orçamento acabou em 25/09/2026 e todo job de repositório privado falhou em
segundos, com zero passos.

| | |
|---|---|
| Endereço | `100.64.100.240` — só na rede do escritório. Espaço RFC 6598: não é roteável da internet |
| Acesso | `ssh samir@100.64.100.240` |
| Painel | `http://100.64.100.240:8080/` — somente leitura, sem login, só na rede do escritório. Mostra os jobs; **não** é por ali que um repositório entra |

**Qualquer repositório pode usar, públicos incluídos** — decisão do dono em
07/10/2026. Até essa data repositório público era proibido, e o motivo não
desapareceu: **um pull request de qualquer fork roda o código do autor dele nesta
máquina**, onde os jobs têm `sudo` sem senha e `docker`, o que é root efetivo
numa máquina dentro da rede do escritório. No lugar da proibição fica um ajuste,
por repositório: *Settings → Actions → Fork pull request workflows → **Require
approval for all external contributors***. Em repositório público na `cicd`, esse
ajuste não é opcional.

**Permissão não é destino.** O job lê
`runs-on: ${{ vars.CI_RUNNER || 'ubuntu-latest' }}`, então nada se move até
alguém setar a variável:
`gh variable set CI_RUNNER --body shvia-ci -R <dono>/<repo>` manda os jobs para a
`cicd`, `gh variable delete CI_RUNNER -R <dono>/<repo>` devolve ao GitHub.
**Nunca sete em escopo de organização** — isso retargeta todos os repositórios de
uma vez, inclusive os públicos que hoje rodam de graça nos runners hospedados.

**Entrar é pré-autorizado; registrar continua sendo ato do dono.** Um runner por
repositório, registrado por SSH com um token de uma hora. Os jobs rodam com
`sudo` numa máquina dentro da rede do escritório, então um agente **nunca
registra runner por iniciativa própria**: ele diz o que falta e pergunta.
Repositório de conta de terceiro não está coberto pela decisão acima — esse
continua sendo decidido caso a caso.

<!-- /CICD-RULE -->
