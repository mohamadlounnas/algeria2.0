import type { HttpContext } from '@adonisjs/core/http'
import User from '#models/user'
import { signUpValidator, signInValidator } from '#validators/auth'

export default class AuthController {
  /**
   * Sign up - Register a new user account
   */
  async signUp({ request, response }: HttpContext) {
    const data = await request.validateUsing(signUpValidator)

    // Check if user already exists
    const existingUser = await User.findBy('email', data.email)
    if (existingUser) {
      return response.status(400).json({
        message: 'User with this email already exists',
      })
    }

    // Create new user
    const user = await User.create({
      email: data.email,
      password: data.password,
      name: data.name,
      role: data.role || 'FARMER',
    })

    // Generate access token
    const token = await User.accessTokens.create(user)

    return response.json({
      token: token.value!.release(),
      user: {
        id: user.id.toString(),
        email: user.email,
        name: user.name,
        role: user.role,
      },
    })
  }

  /**
   * Sign in - Authenticate user and return token
   */
  async signIn({ request, response, auth }: HttpContext) {
    const data = await request.validateUsing(signInValidator)

    try {
      // Verify credentials
      const user = await User.verifyCredentials(data.email, data.password)

      // Generate access token
      const token = await User.accessTokens.create(user)

      return response.json({
        token: token.value!.release(),
        user: {
          id: user.id.toString(),
          email: user.email,
          name: user.name,
          role: user.role,
        },
      })
    } catch (error) {
      return response.status(401).json({
        message: 'Invalid email or password',
      })
    }
  }

  /**
   * Get current authenticated user
   */
  async me({ auth, response }: HttpContext) {
    const user = auth.getUserOrFail()

    return response.json({
      id: user.id.toString(),
      email: user.email,
      name: user.name,
      role: user.role,
      createdAt: user.createdAt.toISO(),
    })
  }
}
