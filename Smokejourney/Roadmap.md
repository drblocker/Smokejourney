# CigarTracker Roadmap

This roadmap outlines the development phases and features for the CigarTracker app.

---

## Phase 1: Foundation and Core Functionality

### 1. Humidor Management
- [ ] Create/manage multiple humidors.
- [ ] Set humidor capacity.
- [ ] Add/remove cigars from humidors.
- [ ] Track humidor location.
- [ ] Search humidors.

### 2. Cigar Management
- [ ] Add cigars with basic details:
  - Brand
  - Name
  - Wrapper type
  - Size
  - Strength
- [ ] Remove cigars from collection.

### 3. Authentication
- [ ] Implement secure user account management.
- [ ] Add user profile management.
- [ ] Add basic privacy settings.

### 4. User Interface (UI) Framework
- [ ] Develop a clean, intuitive tab-based navigation:
  - **Humidors**
  - **Profile**
  - **Settings**
- [ ] Build light/dark mode support.
- [ ] Add basic error handling and loading states.

---

## Phase 2: Advanced Features

### 5. Environmental Monitoring
- [ ] Integrate SensorPush API for temperature and humidity tracking.
- [ ] Display real-time sensor data.
- [ ] Add customizable sensor settings:
  - Temperature/humidity offset calibration.
  - Alert thresholds.

### 6. Notifications
- [ ] Add environmental alerts for temperature and humidity thresholds.
- [ ] Build notification settings UI.

### 7. Data Synchronization
- [ ] Set up Firebase for cloud data storage.
- [ ] Implement offline support with SwiftData local storage.
- [ ] Enable real-time data updates.
- [ ] Add cross-device synchronization.

---

## Phase 3: Enhanced User Experience

### 8. Reviews & Ratings
- [ ] Enable detailed cigar reviews with multiple rating categories.
- [ ] Add photo upload for reviews.
- [ ] Introduce privacy settings for reviews.
- [ ] Add location tagging to reviews.

### 9. Location Services
- [ ] Implement location search and tagging.
- [ ] Allow custom location naming.
- [ ] Integrate map view for tagged locations.

### 10. Advanced UI Enhancements
- [ ] Add pull-to-refresh for real-time updates.
- [ ] Handle empty state views elegantly.
- [ ] Implement robust error feedback mechanisms.

---

## Phase 4: Social Features

### 11. User Profiles
- [ ] Develop detailed profiles with:
  - Profile photos.
  - Bio.
  - Collection showcase.
  - Recent reviews.
- [ ] Add social privacy controls:
  - Profile visibility settings.
  - Collection visibility settings.
  - Review visibility settings.

### 12. Social Interactions
- [ ] Create a follow/unfollow system.
- [ ] Build an activity feed with:
  - Likes.
  - Comments.
  - Mentions.
- [ ] Enable social notifications:
  - New followers.
  - Likes.
  - Comments.

---

## Phase 5: Analytics and Insights

### 13. Historical Data Visualization
- [ ] Add charts for temperature and humidity trends.
- [ ] Enable multiple time range views:
  - 1 Hour.
  - 24 Hours.
  - 7 Days.
  - 30 Days.

### 14. Data Insights
- [ ] Generate usage statistics for cigars and humidors.
- [ ] Provide summaries for user activity (e.g., most-reviewed cigars, average ratings).

---

## Phase 6: Performance Optimization and Final Touches

### 15. Technical Optimizations
- [ ] Use a cache-first approach for faster data access.
- [ ] Monitor network state for seamless offline/online transitions.
- [ ] Optimize background tasks for syncing and data processing.

### 16. Notifications & Alerts
- [ ] Add social notifications for:
  - New followers.
  - Likes.
  - Comments.
  - Mentions.
- [ ] Ensure customizable notification settings.

### 17. Final UI Polishing
- [ ] Test and refine navigation and accessibility.
- [ ] Add advanced search functionality for cigars and humidors.
- [ ] Ensure consistent user experience across all screens.

---

## Deployment and Feedback
- [ ] Release MVP (Minimum Viable Product) with Phases 1–2 completed.
- [ ] Gather user feedback to prioritize Phase 3–6 enhancements.
- [ ] Iterate based on reviews, bug reports, and user suggestions.

---

This roadmap provides a structured approach to ensure steady progress and the inclusion of all planned features.
