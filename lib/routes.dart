import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/conversations_screen.dart';
import 'screens/new_conversation_screen.dart';
import 'screens/simple_profile_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/archived_screen.dart';
import 'screens/help_screen.dart';
import 'screens/about_screen.dart';
import 'services/supabase_service.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String conversations = '/conversations';
  static const String newConversation = '/new-conversation';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String favorites = '/favorites';
  static const String archived = '/archived';
  static const String help = '/help';
  static const String about = '/about';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case conversations:
        return MaterialPageRoute(builder: (_) => const ConversationsScreen());
      case newConversation:
        return MaterialPageRoute(builder: (_) => const NewConversationScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const SimpleProfileScreen());
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case '/favorites':
        return MaterialPageRoute(builder: (_) => const FavoritesScreen());
      case archived:
        return MaterialPageRoute(builder: (_) => const ArchivedScreen());
      case help:
        return MaterialPageRoute(builder: (_) => const HelpScreen());
      case about:
        return MaterialPageRoute(builder: (_) => const AboutScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Página não encontrada'),
            ),
          ),
        );
    }
  }

  static Widget getInitialRoute() {
    final user = SupabaseService.currentUser;
    if (user == null) {
      return const SplashScreen();
    } else {
      return const ConversationsScreen();
    }
  }
}
