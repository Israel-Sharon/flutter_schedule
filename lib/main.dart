// App.js - Works on both iPhone and Android
import React, { useState } from 'react';
import {
View,
Text,
TouchableOpacity,
StyleSheet,
SafeAreaView,
} from 'react-native';

export default function App() {
  const [clickCount, setClickCount] = useState(0);

  const handleButtonPress = () => {
  setClickCount(clickCount + 1);
};

  return (
  <SafeAreaView style={styles.container}>
  <View style={styles.content}>
  <Text style={styles.title}>My iPhone App</Text>

  <Text style={styles.counter}>
  Button tapped: {clickCount} times
  </Text>

  <TouchableOpacity
  style={styles.button}
  onPress={handleButtonPress}
  >
  <Text style={styles.buttonText}>Tap Me!</Text>
  </TouchableOpacity>

  {clickCount > 0 && (
  <Text style={styles.successText}>
  Awesome! You tapped it {clickCount} time{clickCount !== 1 ? 's' : ''}!
  </Text>
  )}

  {clickCount >= 10 && (
  <Text style={styles.achievementText}>
  🎉 Achievement Unlocked: Button Master! 🎉
  </Text>
  )}
  </View>
  </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f0f8ff',
  },
  content: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#1e40af',
    marginBottom: 40,
    textAlign: 'center',
  },
  counter: {
    fontSize: 20,
    color: '#374151',
    marginBottom: 30,
    fontWeight: '500',
  },
  button: {
    backgroundColor: '#007AFF', // iOS blue color
    paddingHorizontal: 40,
    paddingVertical: 16,
    borderRadius: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 4.65,
    elevation: 8,
  },
  buttonText: {
    color: 'white',
    fontSize: 18,
    fontWeight: 'bold',
    textAlign: 'center',
  },
  successText: {
    fontSize: 16,
    color: '#059669',
    marginTop: 25,
    textAlign: 'center',
    fontWeight: '500',
  },
  achievementText: {
    fontSize: 18,
    color: '#DC2626',
    marginTop: 15,
    textAlign: 'center',
    fontWeight: 'bold',
  },
});