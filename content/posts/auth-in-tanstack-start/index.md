---
title: "Implementing secure authentication in Tanstack Start"
author: ["JD"]
date: 2025-04-18
tags: ["tanstack-start", "oauth"]
categories: ["tanstack start"]
draft: true
description: "Home rolling secure authentication and secure session management in Tanstack Start"
ShowToc: true
TocOpen: true
---

OpenID Connect is a secure authentication protocol used by almost every major tech company to allow users to use their authentication system to login to a 3rd party application. It is often confused with OAuth, which itself is an _authorization protocol_ **not** an _authentication protocol_. [This fantastic talk](https://youtu.be/996OiexHze0?si=lbb06KHn5iqehqtv) describes the differences between the two in an easily digestible way and I highly recommend watching it before reading on.

As of writing, there is not a lot of guidance on implementing this generic protocol in Tanstack Start, as it's a relatively new framework. Solutions like [Better Auth](https://better-auth.com) implement the protocol seamlessly and with a simple abstraction, there are scenarios in which you don't have access to a database in order to store user sessions in your running application in which case, Better Auth won't work. This post is going to focus on implementing OpenID Connect in order to use an access token in API requests from the server side to query and mutate data.

## OpenID Connect Flow

The OpenID Connect protocol contains several valid flows for obtaining an access token securely, but the most common one (and one this post focuses on) is the Proof Key of Code Exchange (PKCE) Authorization Flow. There are 3-4 entities that all interact together to fulfill this flow:

- User
- Client (your application)
- Authorization/Identity Server
- Resource Server (sometimes the same as the Authorization/Identity Server)

Each of those entities have a role to play in authenticating and authorizing the user so they can perform the actions they need in your application (the Client). Applications can utilize this flow to authenticate a user with Google, as an Authorization/Identity Server, securely, so we'll use "Sign in with Google" as a frame of reference. The entire flow step by step is the following:

1. User visits Client application
2. User requests access -- they clicked "Sign in with Google"
3. Client generates a `code_verifier` and then with it a `code_challenge` according to Google's specifications
4. Client then sends the `code_challenge`, a `redirect_uri`, and possibly a `client_secret` unique to your application to the proper endpoint required by Google's specifications via HTTP
5. Google responds with a redirect URL to redirect the user to the Google authentication page
6. User enters their Google credentials and clicks sign in and/or provides permissions consent as required
7. Google authenticates the user in their system, and upon success makes a request to the Client callback URL provided to them upon initial Client configuration with an `authorization_code` in a query parameter
8. The Client verifies the `authorization_code` by sending it along with the `code_challenge` to the endpoint to request a token payload for the user
9. Google verifies the `authorization_code` with the `code_challenge` and responds by providing the token payload in the response
10. The client gets the token payload out of the response, which contains the `access_token` and `refresh_token` (among a few other things) and it can use it as required.

There are a few details over looked a bit here but all the steps represent the complete flow. It's important to note, that the **access and refresh tokens are considered private information**, meaning these should not be stored any where in the browser in their original forms. If they happen to leak into the client at any point, it's important to revoke those access tokens in the Authorization/Identity system.

While this seems like a lot of individual steps there is a useful library for abstracting most of these things away into a few simple methods: [ArcticJS](https://arcticjs.dev/).

## ArticJS

ArticJS provides a very useful abstraction to deal with each of the Client steps in an imparative way. Here's an example taken from their documentation on Google authentication:

```javascript
// Initialize the Google client
import * as arctic from "arctic";

const google = new arctic.Google(clientId, clientSecret, redirectURI);

// Crerate the Authentication URL by providing the state, challenge, and required scopes (Steps 3 & 4 & 5 above)
const state = arctic.generateState();
const codeVerifier = arctic.generateCodeVerifier();
const scopes = ["openid", "profile"];
const url = google.createAuthorizationURL(state, codeVerifier, scopes);

// Handle Google response and authorization_code, and retrieve the token data (Steps 8-10)
try {
    const tokens = await google.validateAuthorizationCode(code, codeVerifier);
    const accessToken = tokens.accessToken();
    const accessTokenExpiresAt = tokens.accessTokenExpiresAt();
} catch (e) {
    if (e instanceof arctic.OAuth2RequestError) {
        // Invalid authorization code, credentials, or redirect URI
        const code = e.code;
        // ...
    }
    if (e instanceof arctic.ArcticFetchError) {
        // Failed to call `fetch()`
        const cause = e.cause;
        // ...
    }
    // Parse error
}
```

Each of these blocks will take place at different points in your applications stack and will require some kind of temporary store in order to be able to reference state after a user returns from Google's authorization page.

## Tanstack Start
Under the hood, Tanstack Start uses a library called [h3](https://h3.unjs.io/) to handle it's underlying web framework implementation. We can utilize the exposed APIs of h3 to securely store session data in an **encrypted http-only** cookie so we can then utilize that to make authorized requests to our Resource Server. Here's how you tie everything together in Tanstack Start for secure authentication and authorization via the Open ID Connect protocol.

### Session Data
Since we need to store the iterim state of the authentication flow while the user is on the authentication page of our Authorization/Identity Provider and the final token payload data we'll need two sessions for the whole flow.
1. An AuthenticationSession - the iterim session
2. An UserSession - the final session with the token payload

First, setup your session store by utilizing `useSession` which is exposed from h3 by Tanstack Start. All that's required is a "password" or encryption key to securely encrypt the cookie. This password should be treated as a secret and placed in an environment variable or other secure store that you can reference in your different environments. Make sure you do **not** check the production password into git.

`${PROJECT_ROOT}/.env`
```
SESSION_PASSWORD=abcdefghijklmnopqrstuvwxyzabcdef
```

If preferred, you can create different passwords for each session required for the flow, but for the purposes of this post, we'll just use the one. Some kind of abstraction is necessary so we don't constantly have to reference the environment variables everywhere we want to use the session data. In my project I used a simple set of classes. None of this is specific to Tanstack Start, so you can use whatever implementation you prefer as long as you have access to what you need.

`src/lib/features/auth/session.ts`
```typescript
import { useSession } from '@tanstack/react-start/server'
import env from '~/env'

// Set TSessionData to whatever you need it to be in each sub-class
export abstract class Session<TSessionData extends Record<any, any>> {
  current: ReturnType<typeof useSession<TSessionData>>

  constructor(name: string, maxAge: number) {
    this.current = this._setCurrent(name, maxAge)
  }

  async get(): Promise<TSessionData> {
    const session = await this.current

    return session.data
  }

  async set(sessionData: TSessionData): Promise<void> {
    const session = await this.current

    await session.update(sessionData)
  }

  async clear(): Promise<void> {
    const session = await this.current

    await session.clear()
  }

  private async _setCurrent(name: string, maxAge: number) {
    return await useSession<TSessionData>({
      password: env.SESSION_ENCRYPTION_KEY, // you can use `process.env` here.
      name,
      maxAge,
    })
  }
}
```

Here's the implementation of the `AuthenticationSession`. It has it's own schema and configuration. You can provide any name you want, as long as you know what it is. We sent the expiration time to 1 minute since this session isn't supposed to be used anywhere other than a brief flow.
`src/lib/features/auth/authentication-session.ts`
```typescript
import { Session } from './session'

const SESSION_EXP_TIME = 60 * 1 // 1 minute
const COOKIE_NAME = 'my-app-verify'

export interface IAuthenticationSession {
  state: string
  codeVerifier: string
}
export class AuthenticationSession extends Session<IAuthenticationSession> {
  constructor() {
    super(COOKIE_NAME, SESSION_EXP_TIME)
  }
}
```

Here is the main implementation of the `UserSession`. The session expiration time here is much longer as this will represent the actual session the user will have when interacting with the application.
`src/lib/features/auth/user-session.ts`
```typescript
import { Session } from './session'

const SESSION_EXP_TIME = 60 * 60 * 24 * 7 // 7 days or whatever you want
const COOKIE_NAME = 'my-app-session'

export interface IUserSession {
  username: string
  tokenData: {
    accessToken: string
    expiresIn: Date
    refreshToken: string
  }
  authorization: UserSessionAuthorization
}

export interface SessionData {
  username: string
  isAuthenticated: boolean
}

export class UserSession extends Session<IUserSession> {
  constructor() {
    super(COOKIE_NAME, SESSION_EXP_TIME)
  }
}
```
One thing that's important to note is that the `IUserSession` generic should never be accessible in the client. The `SessionData` represents what is deemed safe to store in the browser.

The `useSession` function will access a non-expired cookie if it exists or it will create a new one if it doesn't, which will make the `Session` classes above behave as singletons. This means anytime you call `new UserSession()` you can reliably assume you'll always have the current session data. Now that the session data is easily accessible, implementing the actual PKCE Authorization flow is next on the docket.

### PKCE Authorization Flow in Tanstack Start
> As mentioned before, there isn't a lot of guidance on how to implement this flow in Tanstack Start quite yet so the best practices might change in the near term. If that does happen, I'll do my best to update this post accordingly.

#### Getting Authorized & Redirecting
Assuming you have set up an application as a Client to an Identity Server of some kind, the very next step is to initiate the authentication flow by generating the code and challenge code, storing those in session data for comparing them to the response later, and requesting the redirect URL for the user to login to the Identity Server. 

The path I chose to take was to implement this logic in an `APIRoute` that would return a redirect response. This appears to be a somewhat naive implementation, but it seems to work pretty flawlessly and allows us to process everything server side just like we need. [Here's the documentation on `APIRoutes`](https://tanstack.com/start/latest/docs/framework/react/api-routes).

In order to keep the code in this `APIRoute` minimal and easily testable, it's better to abstract the interaction away somewhere else, similar to what we did with the session data objects. When I implemented this I was relying on a Key Cloak identity server, so the example follows the required guidelines for that. Use the corresponding APIs from ArcticJS for the identity server you're application uses (they're all about the same.) 

`${PROJECT_ROOT}/src/lib/features/auth/key-cloak-authentication-client.ts`
```typescript
import { decodeIdToken, generateCodeVerifier, generateState, KeyCloak } from 'arctic'
import env from '~/env'
import { AuthenticationSession } from './authentication-session'

export function createAuthorizationURL(baseURL: string): Promise<URL> {
  const realmUrl = `${env.KEYCLOAK_URL}/realms/my-app-realm`
  const redirectURI = `${baseURL}/api/auth/sign-in/callback`
  const authenticationSession = new AuthenticationSession()
  const client = new KeyCloak(realmUrl, env.KC_CLIENT_ID, env.KC_CLIENT_SECRET, redirectURI)

  const state = generateState()
  const codeVerifier = generateCodeVerifier()
  const scopes = ['openid']

  const authorizationUrl = client.createAuthorizationURL(state, codeVerifier, scopes)

  await authenticationSession.set({
    state,
    codeVerifier,
  })

  return authorizationUrl
}
```

> In my implementation, I ended up refactoring this into it's own `Class`. That implementation will be provided below.

This function sets up the required attributes for the `KeyCloak` class from ArcticJS. It uses `CLIENT_ID` and `CLIENT_SECRET`s which should be provided by any identity server. It also uses the `baseURL` parameter to construct the proper `redirectURI`. Most of the time, this is pretty static, but if you're using different environments this might change. This specific parameter will have to be configured based on the setup of a given client application.

Once the code and code verifier have been generated, they're passed into the `Keycloak#createAuthorizationURL` instance method. This method "magically" handles the process of requesting authorization from KeyCloak, sending the code verfier, and obtaining the URL we need to redirect the user to. It also sets the code and the code verifier in the `AuthenticationState` session cookie so we can securely store that info for when the user returns from their redirected authentication flow.

As previously mentioned, we were going to put this logic into an `APIRoute`:

`${PROJECT_ROOT}/src/routes/api/auth/sign-in/index.ts`
```typescript
import { createAPIFileRoute } from '@tanstack/react-start/api'
import { createAuthorizationURL } from '~/lib/features/auth/key-cloak-authentication-client'

export const APIRoute = createAPIFileRoute('/api/auth/sign-in')({
  GET: async ({ request }) => {
    const url = new URL(request.url)

    const authorizationURL = await createAuthorizationURL(url.origin)

    return Response.redirect(authorizationUrl.href, 302)
  },
})
```

The logic in this API is now minimal because everything else is inside of our `createAuthorizationURL` method. First the required `baseURL` parameter is obtained via the `request.url` object and then passed into our main function. Once the authorization URL is obtained, the user can then be redirected to that URL by returning a `Response.redirect`.

At this point, anywhere in the frontend of the application we can just create an `<a>` tag that points to `'/api/auth/sign-in'`.

#### Authentication Callback & Session setting

When a client is setup in an authentication provider, a redirect URI attribute is provided so that the identity provider understands where to redirect the user to with the appropriate parameters. It also passes in a code and challenge code as query parameters, so that the client can verify that the callback request is authorized in it's system.

Several things need to happen in the application when the callback URL is requested:

- Verify the code and challenge exist everywhere we need them to
- Validate the authorization code
- Request the token data payload from the identity server

`${PROJECT_ROOT}/src/lib/features/auth/key-cloak-authentication-client.ts`
```typescript
async function isCallbackRequestVerified(requestCode: string | null, requestState: string | null): Promise<boolean> {
  const session = new AuthenticationSession()
  const verifierSessionData = await session.get()

  const storedState = verifierSessionData.state
  const storedCodeVerifier = verifierSessionData.codeVerifier

  if (
    !requestCode
    || !requestState
    || !storedState
    || !storedCodeVerifier
    || requestState !== storedState
  ) {
    return false
  }

  return true
}
```

This function is only responsible for verifying all the required data exists at this point in the cycle. It's a simple "null check" to help us catch errors earlier in the stack.

Once this returns `true` we know the request is almost authorized and can continue with verifying the challenge and requesting the token data.

`${PROJECT_ROOT}/src/lib/features/auth/key-cloak-authentication-client.ts`
```typescript
// ...
async getSessionData(code: string): Promise<IResult<IUserSession, Error>> {
  const authenticationSession = new AuthenticationSession()
  const authenticationSessionData = await authenticationSession.get()
  const storedVerifier = authenticationSessionData.codeVerifier

  // At this point we want to always clear the AuthenticationSession session out
  await authenticationSession.set({
    state: '',
    codeVerifier: '',
  })

  await authenticationSession.clear()
  
  const realmUrl = `${env.KEYCLOAK_URL}/realms/my-app-realm`
  const redirectURI = `${baseURL}/api/auth/sign-in/callback`
  const client = new KeyCloak(realmUrl, env.KC_CLIENT_ID, env.KC_CLIENT_SECRET, redirectURI)

  try {
    const tokens = await client.validateAuthorizationCode(code, storedVerifier)
    const accessToken = tokens.accessToken()
    const refreshToken = tokens.refreshToken()
    const expiresIn = tokens.accessTokenExpiresAt()
    const tokenData = decodeIdToken(accessToken) as KeyCloakTokenPayload

    return Result.Ok<IUserSession>({
      username: tokenData.email,
      tokenData: {
        accessToken,
        refreshToken,
        expiresIn,
      },
      authorization: {
        roles: tokenData.realm_access.roles,
      },
    })
  }
  catch (error) {
    console.error('Error setting session data:', error)

    return Result.Err(error as Error)
  }
}
```

This logic is the final step in the authentication flow. It pulls the relevant data from the session, gets passed in the authorization code from the request query params, and then validates them against what we have stored in the session. Once complete, it returns the token payload or returns an error via the nifty `Result` object type. All the main "magic" here takes place in `validateAuthorizationCode` which securely compares values and then makes the request out to the identity service to get the token payload we need. _Finally._

The token data is tehn structured into the `IUserSession` type and returned if there are no errors. This can be modified based on an applications needs fairly safely.

> Remember, the token payload cannot exist unprotected in the client.

It's also important to clear out the `AuthenticationSession` here as early as possible so we don't just leave those random codes and challenges in the cookie. This just ensures you don't have some kind of cross contamination when you're trying to perform this authentication flow later down the road.

The final implementation step is implementing the logic of the callback route.

`${PROJECT_ROOT}/src/routes/api/auth/sign-in/callback.ts`
```typescript
import { createAPIFileRoute } from '@tanstack/react-start/api'
import { isCallbackRequestVerified, getSessionData } from '~/lib/features/auth/key-cloak-authentication-client'
import { UserSession } from '~/lib/features/auth/user-session.ts'

export const APIRoute = createAPIFileRoute('/api/auth/sign-in/callback')({
  GET: async ({ request }) => {
    const url = new URL(request.url)
    const requestState = url.searchParams.get('state')
    const requestCode = url.searchParams.get('code')

    const isRequestUnverified = await isCallbackRequestVerified(requestCode, requestState)

    if (isRequestUnverified) {
      return new Response(null, { status: 401 })
    }

    const getSessionDataResult = await getSessionData(requestCode!)

    if (!getSessionDataResult.ok) {
      console.error('Error validating authorization code:', getSessionDataResult.error)

      return new Response(null, { status: 401 })
    }

    const sessionData = getSessionDataResult.value

    const userSession = new UserSession()
    await userSession.set(sessionData)

    return new Response(null, {
      status: 302,
      headers: { Location: '/' },
    })
  },
})
```

This `APIRoute` simply gets the parameters and passes them to the two previously mentioned functions then takes the action of setting the `UserSession` data for us to use as needed.
