import axios from 'axios'

const axiosInstance = axios.create({
  baseURL: '/api',
  timeout: 15000,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  }
})

// Interceptor para anexar o token e o ID do workspace dinamicamente
axiosInstance.interceptors.request.use(
  (config) => {
    // Tenta obter o token da store persistida do Pinia no localStorage
    try {
      const authPersisted = localStorage.getItem('auth')
      if (authPersisted) {
        const authState = JSON.parse(authPersisted)
        if (authState && authState.token) {
          config.headers.Authorization = `Bearer ${authState.token}`
        }
      }
    } catch (error) {
      console.error('Erro ao ler token de autenticação no interceptor:', error)
    }

    // Tenta obter o ID do workspace atual
    try {
      const workspacePersisted = localStorage.getItem('workspace')
      if (workspacePersisted) {
        const workspaceState = JSON.parse(workspacePersisted)
        if (workspaceState && workspaceState.currentWorkspaceId) {
          config.headers['X-Workspace-Id'] = workspaceState.currentWorkspaceId
        }
      }
    } catch (error) {
      console.error('Erro ao ler workspace no interceptor:', error)
    }

    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

export default axiosInstance
