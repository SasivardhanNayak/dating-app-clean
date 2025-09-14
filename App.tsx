import { useState } from 'react';
import { Navigation } from './components/Navigation';
import { WelcomeScreen } from './components/onboarding/WelcomeScreen';
import { AuthScreen } from './components/onboarding/AuthScreen';
import { PreferencesScreen } from './components/onboarding/PreferencesScreen';
import { HomeScreen } from './components/home/HomeScreen';
import { ExploreScreen } from './components/explore/ExploreScreen';
import { MessagesScreen } from './components/messages/MessagesScreen';
import { ProfileScreen } from './components/profile/ProfileScreen';
import { SettingsScreen } from './components/settings/SettingsScreen';

type OnboardingStep = 'welcome' | 'auth' | 'preferences' | 'complete';
type AppScreen = 'home' | 'explore' | 'messages' | 'profile' | 'settings';

export default function App() {
  const [onboardingStep, setOnboardingStep] = useState<OnboardingStep>('welcome');
  const [activeScreen, setActiveScreen] = useState<AppScreen>('home');
  const [isOnboardingComplete, setIsOnboardingComplete] = useState(false);

  // Onboarding flow handlers
  const handleGetStarted = () => {
    setOnboardingStep('auth');
  };

  const handleAuth = () => {
    setOnboardingStep('preferences');
  };

  const handlePreferencesComplete = () => {
    setOnboardingStep('complete');
    setIsOnboardingComplete(true);
  };

  const handleBackToWelcome = () => {
    setOnboardingStep('welcome');
  };

  const handleBackToAuth = () => {
    setOnboardingStep('auth');
  };

  // If onboarding is not complete, show onboarding flow
  if (!isOnboardingComplete) {
    switch (onboardingStep) {
      case 'welcome':
        return <WelcomeScreen onGetStarted={handleGetStarted} />;
      case 'auth':
        return <AuthScreen onBack={handleBackToWelcome} onAuth={handleAuth} />;
      case 'preferences':
        return <PreferencesScreen onBack={handleBackToAuth} onComplete={handlePreferencesComplete} />;
      default:
        return <WelcomeScreen onGetStarted={handleGetStarted} />;
    }
  }

  // Main app content
  const renderActiveScreen = () => {
    switch (activeScreen) {
      case 'home':
        return <HomeScreen />;
      case 'explore':
        return <ExploreScreen />;
      case 'messages':
        return <MessagesScreen />;
      case 'profile':
        return <ProfileScreen />;
      case 'settings':
        return <SettingsScreen />;
      default:
        return <HomeScreen />;
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 relative max-w-md mx-auto border-x border-gray-200 shadow-xl">
      <div className="pb-20">
        {renderActiveScreen()}
      </div>
      <Navigation activeTab={activeScreen} onTabChange={setActiveScreen} />
    </div>
  );
}