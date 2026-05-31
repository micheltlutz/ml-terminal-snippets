# ADR 0001: Registrar decisões com ADRs

## Status

Aceito

## Contexto

O projeto cresceu com múltiplas áreas (SwiftData/iCloud, scaffold Cursor, UI em 3 colunas, SSH/Terminal). Decisões importantes ficavam implícitas no código e em conversas, dificultando onboarding e evolução futura.

## Decisão

Adotar **Architecture Decision Records (ADRs)** em `docs/adr/`, em português, com:

- Um arquivo por decisão (`NNNN-titulo-curto.md`)
- Status explícito (Aceito, Substituído, etc.)
- Índice em `docs/adr/README.md`
- Ligação a partir de `docs/architecture.md` e do README principal

## Consequências

### Positivas

- Histórico claro do *porquê* de cada escolha
- Facilita revisão por humanos e agentes (ver `AGENTS.md`)
- Base para ADRs futuros (Templates, Snippets, iTerm, etc.)

### Negativas

- Custo de manutenção: alterações grandes devem atualizar ou criar ADR

## Template para novos ADRs

```markdown
# ADR NNNN: Título

## Status
Aceito | Proposto | Substituído por ADR-XXXX | Obsoleto

## Contexto
...

## Decisão
...

## Consequências
### Positivas
### Negativas
```
