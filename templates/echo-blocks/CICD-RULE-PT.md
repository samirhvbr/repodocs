<!-- CICD-RULE:repodocs -->

## CI — repositório privado pode usar o runner self-hosted da frota; público, nunca

> Eco marcado. A fonte única é **[samirhvbr/repodocs](https://github.com/samirhvbr/repodocs/blob/master/docs/ci.md)**
> — mude lá, não aqui. Este bloco é regenerado.

**A frota tem uma máquina de CI, a `cicd`: um runner self-hosted do GitHub
Actions que não gasta os minutos hospedados da conta.** Ela existe porque esse
orçamento acabou em 25/09/2026 e todo job de repositório privado falhou em
segundos, com zero passos. O endereço, o acesso e o procedimento estão na fonte e
**não aqui** — este bloco é copiado para repositórios públicos.

**Repositório público nunca recebe esse runner.** Um pull request de fork roda o
código dele na máquina, e a máquina fica na rede do escritório. Repositórios
públicos usam os runners hospedados do GitHub, que são gratuitos para eles. Se
você está prestes a registrar um runner num deles, pare.

**A chave é uma variável do repositório, nunca uma edição do workflow.** O job lê
`runs-on: ${{ vars.CI_RUNNER || 'ubuntu-latest' }}`;
`gh variable set CI_RUNNER --body shvia-ci -R <dono>/<repo>` manda os jobs para a
`cicd`, e `gh variable delete CI_RUNNER -R <dono>/<repo>` devolve ao GitHub.

**Entrar é ato do dono — e entrar com o repositório de um colaborador também.**
Um runner por repositório, registrado por SSH com um token de registro. Os jobs
rodam com `sudo` e `docker` numa máquina dentro da rede do escritório, então um
agente **nunca registra um runner por iniciativa própria**: diz o que falta e
pergunta. O painel da porta 8080 só mostra os jobs — não é por ele que um
repositório entra.

<!-- /CICD-RULE -->
