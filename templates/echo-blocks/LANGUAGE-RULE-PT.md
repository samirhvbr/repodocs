<!-- LANGUAGE-RULE:repodocs -->

## Idioma — este repositório é escrito em português

> Eco marcado. A fonte única é **[samirhvbr/repodocs](https://github.com/samirhvbr/repodocs/blob/master/docs/conventions.md#the-blue3-internal-repositories-are-written-in-portuguese)**
> — mude lá, não aqui. Este bloco é regenerado.

**Tudo que vive neste repositório, ou na interface do GitHub em volta dele, é
escrito em português**: documentos, **mensagens de commit**, títulos e corpos de
pull request, issues, comentários de código, entradas de changelog, notas de
release.

Este é um dos dois repositórios-exceção da regra de inglês da frota, e a
fronteira é o **dono no GitHub**: `BLUE3-ISP/*`, `samirhvbr/blue3-intranet`,
`samirhvbr/blue3-ai-login` e `samirhvbr/blue3-atendimento`. O motivo é o leitor:
ninguém de fora da empresa abre estes repositórios, e boa parte do que se
escreve neles é raciocínio operacional — um incidente, uma fila, um runbook —
onde a precisão da frase é o valor. Traduzir custa mais do que rende.

**Só o idioma muda.** Formato do commit: `X.Y.Z - descrição curta em português`.
A versão vem do `version.md` e é bumpada no mesmo commit. Prefixos de
Conventional Commits (`feat:`, `fix:`, `chore:`) e mensagens vagas de uma
palavra continuam proibidos, um assunto por commit continua valendo, e a entrada
do `CHANGELOG.md` continua sendo escrita antes — o cabeçalho dela **é** o
subject.

**Identificadores de código são em inglês**, aqui como em qualquer repositório
da frota.

O histórico não se reescreve: mensagem em inglês que já está no log fica como
está.

**A `.continue/` é fila, não registro.** Um documento só sai dela quando a coisa
que ele descreve **existe** — tamanho, idioma e desalinho não são condição de
saída. *Produzir* um item da fila é fazer a coisa existir, não editar, traduzir
ou promover o documento; apagá-lo é o último passo do commit que carrega o
trabalho. **Nunca esvazie essa pasta como arrumação.**

**Num repositório que não é nosso, a convenção do upstream vence** — o idioma e
o formato do commit. Abrir um pull request ou uma issue num repositório de
terceiro faz de nós convidados, e convidado escreve na língua da casa. Nosso
`X.Y.Z - descrição` não significa nada lá: eles não têm um `version.md` nosso, e
não há versão nossa para bumpar. Quando não der para saber, escreva **inglês
(US)** — é a regra da casa da frota.

<!-- /LANGUAGE-RULE -->
