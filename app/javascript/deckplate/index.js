// Identifier -> controller table (ADR 0004). Add each controller here as it is built.
const controllers = {}

export function registerDeckplate(application, { only, except } = {}) {
  for (const [identifier, controller] of Object.entries(controllers)) {
    if (only && !only.includes(identifier)) continue
    if (except && except.includes(identifier)) continue
    application.register(identifier, controller)
  }
}
