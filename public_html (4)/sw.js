self.addEventListener('push', function (event) {
    const data = event.data.json();

    self.registration.showNotification(data.title, {
        body: data.body,
        icon: '/assets/icon-192.png',
        badge: '/assets/icon-192.png'
    });
});
