import FunnelsIndex    from './Index.vue';
import FunnelSettings  from './FunnelSettings.vue';
import CardDetailModal from './components/CardDetail.vue';

export default {
  routes: [
    // Settings — must come before the parent funnels route so Vue Router
    // matches /funnels/settings before trying children of /funnels
    {
      path: 'funnels/settings',
      name: 'funnels_settings',
      component: FunnelSettings,
      meta: {
        permissions: ['administrator'],
      },
    },
    {
      path: 'funnels',
      component: FunnelsIndex,
      name: 'funnels_index',
      meta: {
        permissions: ['administrator', 'agent', 'custom_role'],
      },
      children: [
        {
          path: ':funnelId/cards/:cardId',
          name: 'funnels_card_detail',
          component: CardDetailModal,
          meta: {
            permissions: ['administrator', 'agent', 'custom_role'],
          },
        },
      ],
    },
  ],
};
