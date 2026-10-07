## Tarea
- **ID:** T___ · **Carril:** L_ · **Wave:** W_
- **Hallazgos que cierra:** (V-xx, BE-xx, FL-xx, …)
- **Criterios de aceptación (copiados de `docs/v2/TASKS.yaml`):**
  - [ ] …

## Evidencia (obligatoria; sin esto la tarea no pasa a REVIEW)
- **Run de CI en el head SHA (verde):** <!-- URL -->
- **Head SHA:** <!-- sha -->
- **`flutter --version`:**
```
```
- **Extracto de `tool/verify.sh`:**
```
```
- **Métricas (delta contra `docs/v2/metrics.baseline.json`):** cobertura · violaciones del ratchet · bundle web · lecturas/llamada (si aplica)
- **Tests nuevos** (nombre exacto, en particular los allow/deny de reglas):
- **Goldens nuevos o cambiados** (con la justificación de cada cambio visual):
- **Capturas antes / después** (artefacto del CI):

## Tamaño
- Líneas de diff, sin contar lockfiles, goldens ni generados: ___ (tope: 400; si se supera, `size-exception` + ADR)
- ¿Toca rutas protegidas (`tool/`, `.github/`, `analysis_options.yaml`, umbrales, `test/goldens/`)? Si es así, este PR debe ser solo `gate-change`.

## Riesgos y decisiones
- Riesgos:
- Decisiones de `docs/v2/DECISIONS.md` (D-xx) y default implementado:

## NO VERIFICADO
<!-- Lista explícita de lo que NO se pudo verificar y por qué. Vacío = "nada". -->

## Aprobaciones
- [ ] **V (Verificador):** informe en `docs/v2/verify/T___.md`
- [ ] **R (Red Team)**, si toca privacidad, seguridad, pagos, reglas o callables: informe en `docs/v2/redteam/T___.md`
