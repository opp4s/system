import { createRouter, createWebHistory } from 'vue-router'
import AuthLayout from '@/layouts/AuthLayout.vue'
import AppLayout from '@/layouts/AppLayout.vue'
import { useAuthStore } from '@/stores/auth'
import { useWorkspaceStore } from '@/stores/workspace'
import { useToast } from '@/composables/useToast'

const routes = [
  {
    path: '/',
    redirect: '/dashboard'
  },
  {
    path: '/',
    component: AuthLayout,
    meta: { requiresGuest: true },
    children: [
      {
        path: 'login',
        name: 'login',
        component: () => import('@/views/auth/LoginPage.vue')
      },
      {
        path: 'register',
        name: 'register',
        component: () => import('@/views/auth/RegisterPage.vue')
      },
      {
        path: 'forgot-password',
        name: 'forgot-password',
        component: () => import('@/views/auth/ForgotPasswordPage.vue')
      },
      {
        path: 'reset-password',
        name: 'reset-password',
        component: () => import('@/views/auth/ResetPasswordPage.vue')
      }
    ]
  },
  {
    path: '/',
    component: AppLayout,
    meta: { requiresAuth: true },
    children: [
      {
        path: 'dashboard',
        name: 'dashboard',
        component: () => import('@/views/DashboardPage.vue')
      },
      {
        path: 'contacts',
        name: 'contacts',
        component: () => import('@/views/ContactsPage.vue')
      },
      {
        path: 'automations',
        name: 'automations',
        component: () => import('@/views/AutomationsPage.vue')
      },
      {
        path: 'broadcasts',
        name: 'broadcasts',
        component: () => import('@/views/BroadcastsPage.vue')
      },
      {
        path: 'pipelines',
        name: 'pipelines',
        component: () => import('@/views/pipelines/PipelinesPage.vue'),
        children: [
          {
            path: ':id',
            name: 'pipelines-detail',
            component: () => import('@/views/pipelines/KanbanBoard.vue'),
            children: [
              {
                path: 'cards/:cardId',
                name: 'card-detail',
                component: () => import('@/views/pipelines/CardDetail.vue')
              }
            ]
          }
        ]
      },
      {
        path: 'pipelines/settings',
        name: 'pipeline-settings',
        component: () => import('@/views/pipelines/PipelineSettings.vue')
      },
      {
        path: 'settings',
        redirect: '/settings/whatsapp'
      },
      {
        path: 'settings/whatsapp',
        name: 'settings-whatsapp',
        component: () => import('@/views/settings/WhatsAppSetup.vue')
      }
    ]
  },
  {
    path: '/onboarding',
    name: 'onboarding',
    component: () => import('@/views/OnboardingPage.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/:pathMatch(.*)*',
    redirect: '/dashboard'
  }
]

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes
})

router.beforeEach((to, from, next) => {
  const authStore = useAuthStore()
  const workspaceStore = useWorkspaceStore()
  const toast = useToast()

  const isAuthenticated = !!authStore.token

  // 1. requiresAuth Guard
  if (to.meta.requiresAuth && !isAuthenticated) {
    next({ name: 'login' })
    return
  }

  // 2. requiresGuest Guard
  if (to.meta.requiresGuest && isAuthenticated) {
    next({ name: 'dashboard' })
    return
  }

  // 3. requiresAdmin Guard
  if (to.meta.requiresAdmin) {
    if (!isAuthenticated) {
      next({ name: 'login' })
      return
    }
    const userRole = workspaceStore.currentWorkspace?.role || 'membro'
    if (userRole !== 'admin') {
      toast.error('Acesso negado. Apenas administradores do workspace podem acessar esta página.')
      next({ name: 'dashboard' })
      return
    }
  }

  next()
})

export default router
