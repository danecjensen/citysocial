const storageKey = "citysocial.posthog.identified_user"

function storedIdentity() {
  try {
    return window.localStorage.getItem(storageKey)
  } catch (_error) {
    return null
  }
}

function rememberIdentity(distinctId) {
  try {
    if (distinctId) window.localStorage.setItem(storageKey, distinctId)
    else window.localStorage.removeItem(storageKey)
  } catch (_error) {
    // Analytics persistence must never affect the product experience.
  }
}

function personProperties(body) {
  try {
    return JSON.parse(body.dataset.posthogPersonProperties || "{}")
  } catch (_error) {
    return {}
  }
}

function syncPostHogIdentity() {
  if (!window.posthog || !document.body) return

  const distinctId = document.body.dataset.posthogDistinctId
  const previousDistinctId = storedIdentity()
  const sdkDistinctId = window.posthog.get_distinct_id()

  if (distinctId && distinctId !== previousDistinctId) {
    window.posthog.identify(distinctId, personProperties(document.body))
    rememberIdentity(distinctId)
  } else if (!distinctId && (previousDistinctId || sdkDistinctId?.startsWith("user_"))) {
    window.posthog.reset()
    rememberIdentity(null)
  }
}

document.addEventListener("turbo:load", syncPostHogIdentity)
document.addEventListener("DOMContentLoaded", syncPostHogIdentity, { once: true })
window.addEventListener("posthog:loaded", syncPostHogIdentity)
