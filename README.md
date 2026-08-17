# JagX Nexus

So we are going to build JagX AI using JagX API key ```markdown

# JagX AI API Documentation



**Version:** 4.2  

**Base URL:** `https://jagx-ai-v2.onrender.com`  

**Created by:** JagX & JRILICENSE



---



## Authentication



All protected endpoints require the following header:



```http

x-api-key: your_jagx_api_key

```



Example:

```http

x-api-key: jagx-17bc9b71804423db952c76594ea6b071

```



---



## 1. Root / Health Check



**Endpoint:** `GET /`



**Description:** Check if the API is running.



**Example Response:**



```json

{

  "status": "JagX AI 4.2 is running",

  "version": "4.2.0",

  "created_by": "JagX & JRILICENSE",

  "features": [

    "hourly_rate_limit",

    "key_management",

    "local_knowledge",

    "free_search",

    "invisible_watermark"

  ]

}

```



---



## 2. Create API Key



**Endpoint:** `POST /create-key`



**Description:** Create a new API key (Admin only).



**Headers:**

```http

Content-Type: application/json

```



**Request Body:**



```json

{

  "owner_label": "John Doe",

  "admin_secret": "your_admin_secret",

  "tier": "free"

}

```



**Available Tiers:**



| Tier           | Requests per Hour |

|----------------|-------------------|

| free           | 60                |

| premium        | 300               |

| premium_plus   | 800               |

| master         | Unlimited         |

| admin          | Unlimited         |



**Success Response:**



```json

{

  "api_key": "jagx-xxxxxxxxxxxxxxxx",

  "owner": "John Doe",

  "tier": "free",

  "hourly_limit": 60

}

```



---



## 3. Chat (Main Endpoint)



**Endpoint:** `POST /chat`



**Description:** Send a message to JagX AI and receive a response.  

Every response contains an **invisible watermark**.



**Headers:**

```http

Content-Type: application/json

x-api-key: your_jagx_api_key

```



**Request Body:**



```json

{

  "message": "Who are you?",

  "max_tokens": 1200,

  "history": [

    {

      "role": "user",

      "content": "Hello"

    },

    {

      "role": "assistant",

      "content": "Hi! How can I help you?"

    }

  ]

}

```



**Success Response:**



```json

{

  "response": "I am JagX AI, created by JagX and JRILICENSE...",

  "model": "JagX AI 4.2",

  "quota": "45 requests remaining this hour"

}

```



---



## 4. List All Keys (Admin)



**Endpoint:** `GET /admin/keys`



**Headers:**

```http

admin_secret: your_admin_secret

```



**Success Response:**



```json

{

  "total": 2,

  "keys": [

    {

      "api_key": "jagx-xxxxxxxx",

      "owner": "John Doe",

      "tier": "free",

      "active": true,

      "created_at": 1723812345.123

    }

  ]

}

```



---



## 5. Block / Unblock Key (Admin)



**Endpoint:** `POST /admin/block-key`



**Request Body:**



```json

{

  "api_key": "jagx-xxxxxxxx",

  "active": false,

  "admin_secret": "your_admin_secret"

}

```



**Success Response:**



```json

{

  "success": true,

  "message": "Key updated successfully"

}

```



---



## 6. Delete Key (Admin)



**Endpoint:** `POST /admin/delete-key`



**Request Body:**



```json

{

  "api_key": "jagx-xxxxxxxx",

  "admin_secret": "your_admin_secret"

}

```



**Success Response:**



```json

{

  "success": true,

  "message": "Key deleted successfully"

}

```



---



## 7. Upgrade Key Tier (Admin)



**Endpoint:** `POST /admin/upgrade-key`



**Request Body:**



```json

{

  "api_key": "jagx-xxxxxxxx",

  "new_tier": "premium",

  "admin_secret": "your_admin_secret"

}

```



**Success Response:**



```json

{

  "success": true,

  "message": "Key upgraded to premium",

  "hourly_limit": 300

}

```



---



## Rate Limits



| Tier          | Requests per Hour |

|---------------|-------------------|

| free          | 60                |

| premium       | 300               |

| premium_plus  | 800               |

| master        | Unlimited         |

| admin         | Unlimited         |



When the limit is exceeded, the API returns:



```json

{

  "detail": "Hourly limit reached (60 requests/hour). Please wait or upgrade."

}

```



---



## Error Codes



| Status Code | Meaning                     |

|-------------|-----------------------------|

| 401         | Invalid or inactive API key |

| 403         | Invalid admin secret        |

| 404         | Key not found               |

| 429         | Rate limit exceeded         |

| 500         | Server error                |



---



## Important Notes



- Every text response from `/chat` contains an **invisible watermark of within the JagX AI environment**.

- Permanent keys can be set using the environment variable `JAGX_PERMANENT_KEYS`.

- The AI always identifies itself as **JagX AI by JagX & JRILICENSE**.



---



**© 2026 JagX & JRILICENSE**

```i think does are the documentation that will help you reach JagX Api key so Lovable all what you will create here you will create it like you creating for a big company like Space X,X meta and more so make sure everything in here are customized and comfortable and is good at different things and also make sure it as no limit and have different grade make sure the ai is perfect and make sure the logo that will show on Google as the logo is not lovable badge so create a very unique ai which will have terminal for coding and more and in some cases can access users device with permission given to it so keep it advance in coding and also generate things from the internet not just using the API key alone it should be able to gather information from the internet

This project was built with [Lovable](https://lovable.dev).

## Build with Lovable

Continue developing this project in the [Lovable editor](https://lovable.dev/projects/14f386db-be72-41ee-b83b-f949390c06cd).

- **Ship faster**: describe what you want to build and Lovable handles the code.
- **Stay in sync**: every change made in Lovable is committed straight to this repository.
- **Full ownership**: this code is yours. Push to `main` on GitHub and your changes sync back into Lovable, ready for your next prompt.

## Development

Prefer working locally? You need Node.js and npm — [install with nvm](https://github.com/nvm-sh/nvm#installing-and-updating).

```sh
git clone <this-repository-url>
cd <repository-name>
npm i
npm run dev
```
