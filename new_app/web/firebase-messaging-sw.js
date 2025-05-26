importScripts('https://www.gstatic.com/firebasejs/9.19.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.19.1/firebase-messaging-compat.js');

firebase.initializeApp({
apiKey: 'AIzaSyAQ81qqH-vCXldPoCpGqxBLTHU7aoP1DyI',
    appId: '1:865558148469:web:85e36f46b8ad1b8e474f3c',
    messagingSenderId: '865558148469',
    projectId: 'hilgo-cargo-project-e0dbc',
    authDomain: 'hilgo-cargo-project-e0dbc.firebaseapp.com',
    storageBucket: 'hilgo-cargo-project-e0dbc.firebasestorage.app',
    measurementId: 'G-76PRD3R488',
});

const messaging = firebase.messaging();
