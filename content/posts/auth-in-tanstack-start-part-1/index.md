---
title: "Authentication in Tanstack Start: Part 1 - The Protocol"
author: ["JD"]
date: 2025-04-19
tags: ["tanstack-start", "oauth", "openid connect"]
categories: ["tanstack start", "authentication"]
draft: true
mermaid: true
description: "In this series we're going over how to implement the OpenID Connect PKCE authorization flow within Tanstack start. This first post is a deep dive into the protocol itself."
ShowToc: true
TocOpen: true
---

{{< standout >}}
Series Overview
{{< /standout >}}

[Tanstack Start](https://tanstack.com/start) TanStack Start is a new JavaScript framework by Tanner Linsley. As of writing, it's still in beta and lacks comprehensive guidance for implementing authentication — especially since most 3rd-party libraries haven't fully caught up.

This series explores how to implement secure authentication in a TanStack Start application using OpenID Connect. In Part 1, we'll explore the protocol and PKCE flow. In Part 2, we’ll dive into a concrete implementation inside a TanStack Start app.

{{< standout >}}
Part 1 - OpenID Connect Protocol with PKCE Authorization Flow
{{< /standout >}}

OpenID Connect is a secure authentication protocol used by almost every major tech company to allow users to use their authentication system to login to a different application known as the Client. It is often confused with OAuth, which itself is an _authorization protocol_ **not** an _authentication protocol_. This talk offers an excellent breakdown of the differences between OAuth 2 and OpenID Connect, and is worth watching for a conceptual overview.

{{< youtube 996OiexHze0 >}}

OpenID Connect supports several flows for securely obtaining an access token. The most common (and the focus of this series) is the PKCE Authorization Flow.. There are four entities that all interact together to fulfill this highly secure flow. There are other flows possible with OpenID Connect, however, those are out of scope of this series.

## OpenID Connect Actors
### User
Users interact with the Client Application in order to authenticate with their own credentials on the Identity Server. From the user's perspective, they are briefly redirected to a familiar provider like Google or GitHub to log in, then returned to the original application as an authenticated user.

### Client Application
The Client Application is usually required to register with the Identity Server/Identity Provider before anything else can be done. Typically attributes such as the client applicaiton URL, trusted hosts, and a redirect URI are provided so that the Identity Server/Identity Provider knows how to communicate with the Client during the course of an authentication flow.

The redirect URI is where the Identity Server will send the user back to after authentication. It typically includes query parameters (e.g., an authorization code), which the Client Application can use to complete the flow and retrieve token data.

### Identity Server/Identity Provider
The Identity Server acts as the gatekeeper to the Resource Server. In many implementations, these are the same system, but conceptually they serve different roles. It provides the authentication keys and configuration for Clients. It's also responsible for maintaining the User credentials as well as generating the dynamic access tokens so requests from the Client can be made "with the authenticated user context" in mind.

### Resource Server
The Resource Server is just representative of the data a User needs access to in the course of interacting with the Client. For instance, if you try to obtain private repository information from Github, you'll need the Users access keys in your request so Github knows that the request for private information is made by the User the information belongs to. Typically, the Resource Server will validate the `access_token` with the Identity Provider in order to verify a given request is authenticated.

> 📌 Note: These roles and terms are standard across OpenID Connect discussions, and we’ll refer to them frequently throughout the series.

## OpenID Connect Objects


## OpenID Connect Flow

{{< mermaid >}}
 sequenceDiagram
  participant User
  participant Client
  participant AuthServer as Authorization Server

  User->>Client: Clicks "Sign in with Google"
  Client->>Client: Generate code_verifier
  Client->>Client: Derive code_challenge from code_verifier
  Client->>AuthServer: Redirect to /authorize\nwith code_challenge, client_id, etc.
  AuthServer->>User: Show login and consent screen
  User->>AuthServer: Enter credentials, approve access
  AuthServer->>AuthServer: Validate credentials\nand generate authorization_code
{{< /mermaid >}}

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

