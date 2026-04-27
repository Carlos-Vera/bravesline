# bravesline

Una statusline para [Claude Code](https://claude.ai/code) que te muestra lo que necesitas saber mientras codeas — sin salir del terminal.

```
myapp ( main ↑2 ≡1 ●) | Claude Sonnet 4.6 | cntxto:[████████░░░░░░░░░░░░] 40% usado ses:5.2k(3.1ktok) | 5h:[████░░░░░░] 40% 7d:[██░░░░░░░░] 20%
```

## Qué muestra

- **Git** — rama con icono ``, commits adelante/atrás del remote, stash, y un `●` verde si está limpio o rojo con el conteo si hay cambios sin commit
- **Contexto** — barra visual con colores (cyan → amarillo → rojo), porcentaje de uso, tokens de la sesión y del contexto actual
- **Rate limits** — barras para la ventana de 5h y 7 días, con cuenta regresiva hasta el reset
- **Sin repo** — muestra `No Git` si el directorio no tiene git
- **Idiomas** — etiquetas según tu locale: `en`, `es`/`ca`, `fr`, `pt`, `it`

## Requiere

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- `bash`, `jq`, `bc`, `git`

## Instalación

Una línea y listo:

```bash
F=~/.claude/settings.json; [ -f "$F" ] || echo '{}' > "$F"; \
curl -fsSL https://raw.githubusercontent.com/Carlos-Vera/bravesline/main/bravesline.sh \
  -o ~/.claude/bravesline.sh && \
jq '.statusLine = {"type":"command","command":"bash ~/.claude/bravesline.sh","padding":0}' \
  "$F" > /tmp/_bl.json && mv /tmp/_bl.json "$F"
```

Reinicia Claude Code y aparece de inmediato.

## Referencia de secciones

| Sección | Qué indica |
|---|---|
| `folder ( branch)` | Directorio actual y rama |
| `↑N ↓N` | Commits adelante / atrás del remote |
| `≡N` | Entradas en el stash |
| `●` verde / `↑N ●` rojo | Limpio — o cuántos archivos tienen cambios sin commit |
| `cntxto/ctx:[barra] N%` | Uso de la ventana de contexto |
| `ses:Nk` | Tokens totales de la sesión (input + output) |
| `(Nktok)` | Tokens en el contexto actual |
| `5h:[barra]` | Uso del rate limit de 5 horas |
| `7d:[barra]` | Uso del rate limit de 7 días |
| `↺Xh Ym` | Tiempo hasta que se resetea el límite |

## Colores

| Color | Qué significa |
|---|---|
| Cyan / Verde | Bajo del 50% — sin preocupaciones |
| Amarillo | Entre 50–79% — ojo |
| Rojo | 80% o más — actúa |

---

Hecho para la comunidad por [Carlos Vera](mailto:carlos@braveslab.com) · [BravesLab](https://braveslab.com)  
*Toda la gloria a mi Padre, Jesucristo*
