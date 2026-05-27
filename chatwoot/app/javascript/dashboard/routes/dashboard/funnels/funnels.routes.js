import FunnelsIndex from './Index.vue';
import CardDetailModal from './components/CardDetail.vue';

export default {
  routes: [
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
