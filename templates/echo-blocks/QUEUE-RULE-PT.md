<!-- QUEUE-RULE:repodocs -->

## A fila esvazia por produção, e por mais nada

> Eco marcado. A fonte única é **[samirhvbr/repodocs](https://github.com/samirhvbr/repodocs/blob/master/docs/conventions.md#1-continue-is-the-queue--docs-is-what-has-been-produced)**
> — mude lá, não aqui. Este bloco é regenerado.

**A `.continue/` guarda trabalho que ainda não existe.** Um documento só sai dela
quando — e **somente quando** — a coisa que ele descreve **existe**. Tamanho não
é condição de saída. Idade, idioma, desalinho, fim de sessão e agente que teria
escrito diferente também não.

> `tela.md` diz *"uma tela preta com uma bola amarela no meio"*. Ele sai da fila
> quando existir uma tela preta com uma bola amarela. Até lá ele fica, do
> tamanho que for, na forma em que estiver — porque até lá ele é o único lugar
> onde essa tela existe.

**"Produzir" um item da fila é fazer a coisa existir.** Não é editar o
documento, não é traduzir, não é promover para `docs/`. O documento é a
especificação; a entrega é a coisa. Apagar o documento é o **último passo do
commit que carrega o trabalho** — nunca um passo sozinho.

**Nunca esvazie essa pasta como arrumação.** Um item apagado sem o trabalho
feito destrói o único artefato que um projeto tem antes de ter código — e o que
costuma ficar no lugar é pior que a perda: uma página em `docs/` descrevendo uma
tela que ninguém construiu, indistinguível de uma que descreve algo que existe.
Se um plano precisa aparecer em `docs/` antes de ser construído, ele é
`PROPOSED`, nunca `ACTIVE`.

**A regra da meia página é sobre registro que foi parar na fila**, e sobre nada
mais. Ela não tem opinião sobre o tamanho de uma especificação de coisa não
feita: um brief de 1.300 linhas sobre algo que não existe está no único lugar
onde pode estar. Item longo é projeto com muita coisa por construir.

<!-- /QUEUE-RULE -->
