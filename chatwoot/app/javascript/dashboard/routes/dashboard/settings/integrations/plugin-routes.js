import WhatsappLiteIndex from './WhatsappLite/Index.vue';

export default [
  {
    path: 'whatsapp_lite',
    name: 'settings_integrations_whatsapp_lite',
    component: WhatsappLiteIndex,
    meta: { permissions: ['administrator'] },
  },
];
