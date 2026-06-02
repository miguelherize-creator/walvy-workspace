# Diagrama de Caminos de la Aplicacion (Etapa 1)

```mermaid
flowchart TD
    A[App Start] --> B{AuthProvider isLoading?}
    B -- Si --> C[Mostrar loader en index]
    B -- No --> D{isAuthenticated?}

    D -- Si --> E[Dashboard]
    D -- No --> F[Login]

    %% Login
    F --> G[Ingresar email + contrasena]
    G --> H{Credenciales validas?}
    H -- No --> F1[Mostrar error]
    F1 --> F
    H -- Si --> I{Biometria disponible y no activada?}
    I -- Si --> J[Prompt activar biometria]
    J --> E
    I -- No --> E

    %% Reingreso biometrico
    F --> K{Biometria activa + token guardado?}
    K -- Si --> L[Boton Entrar con Face ID / Huella]
    L --> M{Autenticacion biometrica exitosa?}
    M -- Si --> E
    M -- No --> F

    %% Registro
    F --> N[Ir a Register]
    N --> O[Crear cuenta]
    O --> P{Registro exitoso?}
    P -- Si --> E
    P -- No --> N

    %% Recuperacion
    F --> Q[Olvide mi contrasena]
    Q --> R[Paso 1: enviar email]
    R --> S[Paso 2: token + nueva contrasena]
    S --> T{Reset exitoso?}
    T -- Si --> F
    T -- No --> S

    %% Dashboard acciones
    E --> U[Toggle biometria on/off]
    E --> V[Cambio de contrasena]
    V --> W{Cambio exitoso?}
    W -- Si --> E
    W -- No --> V

    E --> X[Cerrar sesion]
    X --> Y{Biometria activa?}
    Y -- Si --> Z[Logout tipo lock: conserva token local]
    Z --> F
    Y -- No --> AA[Logout completo: limpia token]
    AA --> F
```

## Lectura rapida

- `index` decide a donde navegar segun `isAuthenticated`.
- `login` soporta entrada normal + entrada biometrica.
- `forgot-password` opera en 2 pasos (solicitud + reset).
- `dashboard` concentra ajustes de seguridad (biometria y cambio de contrasena).
