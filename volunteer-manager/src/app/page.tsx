'use client';

import { useState, useEffect } from 'react';

export default function Home() {
  const [user, setUser] = useState<any>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [wordpressUrl, setWordpressUrl] = useState<string>('');

  useEffect(() => {
    // Get the WordPress URL from the iframe's referrer
    // This ensures we're making API requests to the correct WordPress instance
    if (typeof window !== 'undefined') {
      // Default to localhost if in development environment
      const referrer = document.referrer || 'http://localhost/wordpress';
      const url = new URL(referrer);
      setWordpressUrl(`${url.protocol}//${url.host}`);
    }
  }, []);

  useEffect(() => {
    // Only proceed if we have determined the WordPress URL
    if (!wordpressUrl) return;

    const fetchUserData = async () => {
      try {
        setLoading(true);
        
        // Get JWT from localStorage (set by WordPress)
        const jwt = localStorage.getItem('wp_jwt');
        
        if (!jwt) {
          setUser(null);
          setError('No authentication token found');
          setLoading(false);
          return;
        }
        
        // Fetch user data from WordPress REST API
        const response = await fetch(`${wordpressUrl}/wp-json/wp/v2/users/me`, {
          headers: {
            'Authorization': `Bearer ${jwt}`,
            'Content-Type': 'application/json'
          }
        });
        
        if (!response.ok) {
          throw new Error('Failed to authenticate with WordPress');
        }
        
        const userData = await response.json();
        setUser(userData);
        setError(null);
      } catch (err: any) {
        console.error('Authentication error:', err);
        setUser(null);
        setError(err.message || 'Failed to fetch user data');
      } finally {
        setLoading(false);
      }
    };
    
    fetchUserData();
  }, [wordpressUrl]);

  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-16">
      <h1 className="text-3xl font-bold mb-8 text-center">
        Volunteer Manager
      </h1>

      <div className="bg-gray-50 rounded-lg shadow-md p-8 w-full max-w-md text-center">
        {loading ? (
          <p className="text-gray-600">Loading user data...</p>
        ) : error ? (
          <div className="text-red-600">
            <p>Error: {error}</p>
            <p className="mt-2">Please log in to WordPress to view this content.</p>
          </div>
        ) : user ? (
          <div className="flex flex-col items-center">
            <h2 className="text-2xl font-semibold text-blue-600 mb-2">Welcome, {user.name}!</h2>
            <p className="text-gray-700">You are successfully authenticated with the Volunteer Manager.</p>
          </div>
        ) : (
          <p className="text-gray-700">Please log in to WordPress to view this content.</p>
        )}
      </div>
    </main>
  );
}