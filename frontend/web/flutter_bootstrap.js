{{flutter_js}}
{{flutter_build_config}}

// Unregister old service workers to ensure fresh content on every load
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.getRegistrations().then(function(registrations) {
    for (let registration of registrations) {
      registration.unregister();
    }
  });
}

_flutter.loader.load();
