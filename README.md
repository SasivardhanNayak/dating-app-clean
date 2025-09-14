# DateXY - Modern Dating App

A comprehensive dating application built with React, TypeScript, and Tailwind CSS featuring onboarding, swipe-based discovery, messaging, and user profiles.

## 🚀 Quick Deploy

### Deploy to Vercel (Recommended)

1. **Push to GitHub:**
   ```bash
   git init
   git add .
   git commit -m "Initial commit - DateXY dating app"
   git remote add origin YOUR_GITHUB_REPOSITORY_URL
   git branch -M main
   git push -u origin main
   ```

2. **Deploy:**
   - Go to [vercel.com](https://vercel.com)
   - Sign in with GitHub
   - Click "New Project"
   - Import your repository
   - Click "Deploy"

### Deploy to Netlify

1. **Build Command:** `npm run build`
2. **Publish Directory:** `dist`
3. **Deploy:** Drag the `dist` folder to [netlify.com/drop](https://netlify.com/drop)

## 🛠️ Local Development

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

## 📱 Features

- **Onboarding Flow:** Welcome, authentication, and preferences setup
- **Swipe Discovery:** Card-based user discovery with like/pass actions
- **User Profiles:** Comprehensive profile management
- **Explore Tab:** Advanced filtering and discovery options
- **Messaging:** Real-time chat functionality
- **Settings:** Account management and safety features

## 🏗️ Tech Stack

- **Framework:** React 18 with TypeScript
- **Styling:** Tailwind CSS v4
- **Build Tool:** Vite
- **UI Components:** Radix UI + shadcn/ui
- **Icons:** Lucide React
- **Animations:** Motion (Framer Motion)

## 📂 Project Structure

```
├── components/
│   ├── onboarding/     # Welcome, auth, preferences
│   ├── home/           # Swipe cards and home screen
│   ├── explore/        # Discovery and filtering
│   ├── messages/       # Chat functionality
│   ├── profile/        # User profile management
│   ├── settings/       # App settings
│   └── ui/             # Reusable UI components
├── styles/             # Global CSS and themes
├── utils/              # Utility functions
└── supabase/           # Database schema and functions
```

## 🔧 Configuration

- **Vite Config:** `vite.config.ts`
- **TypeScript:** `tsconfig.json`
- **Styling:** `styles/globals.css`
- **Dependencies:** `package.json`

## 🌐 Environment Variables

For production deployment with backend features:

```env
VITE_SUPABASE_URL=your_supabase_url
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
```

## 📄 License

Private project - All rights reserved.

---

**User:** e/nayak | **App:** DateXY Dating Platform