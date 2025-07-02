#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
using namespace metal;

// Enhanced noise functions
float hash(float2 p) {
    return fract(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453123);
}

float smoothNoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    
    float a = hash(i);
    float b = hash(i + float2(1.0, 0.0));
    float c = hash(i + float2(0.0, 1.0));
    float d = hash(i + float2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// HSV to RGB conversion
float3 hsv2rgb(float3 c) {
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// Create beautiful gradient colors
float3 createGradientColor(float hue, float intensity, float variation) {
    float adjustedHue = fract(hue + variation * 0.3);
    float saturation = 0.8 + intensity * 0.2;
    float brightness = 0.6 + intensity * 0.4;
    return hsv2rgb(float3(adjustedHue, saturation, brightness));
}

// Create perfectly circular dots using square grid cells
float perfectCircularDot(float2 position, float2 size, float gridSize, float dotSize) {
    // Use the smaller dimension to ensure square cells
    float cellSize = min(size.x, size.y) / gridSize;
    
    // Calculate grid coordinates
    float2 gridCoord = floor(position / cellSize);
    
    // Center of current grid cell
    float2 cellCenter = (gridCoord + 0.5) * cellSize;
    
    // Distance from position to cell center (in pixels)
    float distanceToCenter = length(position - cellCenter);
    
    // Dot radius in pixels
    float dotRadius = cellSize * dotSize * 0.4;
    
    // Create smooth circular dot
    return 1.0 - smoothstep(dotRadius - 1.0, dotRadius + 1.0, distanceToCenter);
}

// Simple fallback shader with perfect circles
[[ stitchable ]] half4 dotGridFallback(float2 position, half4 color, float2 size) {
    float dot = perfectCircularDot(position, size, 20.0, 0.6);
    return half4(half3(dot * 0.5), color.a);
}

// PATTERN 1: Flowing Ocean Wave Dots
[[ stitchable ]] half4 dotGridWave(float2 position, half4 color, float2 size, float time, float density, float dotSize, float colorHue, float colorEnabled) {
    // Grid size based on density
    float gridSize = mix(12.0, 35.0, density);
    float cellSize = min(size.x, size.y) / gridSize;
    
    // Calculate grid coordinates
    float2 gridCoord = floor(position / cellSize);
    float2 cellCenter = (gridCoord + 0.5) * cellSize;
    
    // Normalized position for wave calculations
    float2 normalizedPos = position / min(size.x, size.y);
    float2 normalizedGrid = gridCoord / gridSize;
    
    // Create flowing wave effect
    float wave1 = sin(normalizedGrid.x * 2.0 + normalizedPos.y * 6.0 + time * 3.0) * 0.4;
    float wave2 = cos(normalizedGrid.y * 1.5 + normalizedPos.x * 4.0 + time * 2.0) * 0.3;
    float waveOffset = wave1 + wave2;
    
    // Animated dot size based on wave
    float animatedDotSize = dotSize * (0.8 + waveOffset * 0.4);
    
    // Distance from position to cell center
    float distanceToCenter = length(position - cellCenter);
    float dotRadius = cellSize * animatedDotSize * 0.35;
    
    // Create perfect circle
    float dot = 1.0 - smoothstep(dotRadius - 1.0, dotRadius + 1.0, distanceToCenter);
    
    // Color intensity based on wave
    float intensity = 0.4 + 0.6 * (0.5 + 0.5 * sin(waveOffset * 2.0 + time));
    
    // Create colors based on toggle
    float3 finalColor;
    if (colorEnabled > 0.5) {
        finalColor = createGradientColor(colorHue, intensity, waveOffset);
    } else {
        finalColor = float3(intensity);
    }
    
    return half4(half3(finalColor * dot), color.a);
}

// PATTERN 2: Hypnotic Breathing Pulse
[[ stitchable ]] half4 dotGridPulse(float2 position, half4 color, float2 size, float time, float density, float dotSize, float colorHue, float colorEnabled) {
    float gridSize = mix(10.0, 30.0, density);
    float cellSize = min(size.x, size.y) / gridSize;
    
    float2 gridCoord = floor(position / cellSize);
    float2 cellCenter = (gridCoord + 0.5) * cellSize;
    
    // Distance from center of screen (in normalized coordinates)
    float2 screenCenter = size * 0.5;
    float distFromScreenCenter = length(position - screenCenter) / min(size.x, size.y);
    
    // Create multiple pulse rings
    float pulseSpeed = 2.5;
    float pulse1 = sin(distFromScreenCenter * 12.0 - time * pulseSpeed) * 0.5 + 0.5;
    float pulse2 = sin(distFromScreenCenter * 18.0 - time * pulseSpeed * 1.3) * 0.3 + 0.7;
    float pulse3 = sin(distFromScreenCenter * 6.0 - time * pulseSpeed * 0.7) * 0.2 + 0.8;
    
    // Combine pulses
    float pulseEffect = pulse1 * pulse2 * pulse3;
    
    // Breathing effect
    float breathe = sin(time * 1.5) * 0.2 + 0.8;
    float animatedDotSize = dotSize * breathe * (0.5 + pulseEffect * 0.6);
    
    // Distance from position to cell center
    float distanceToCenter = length(position - cellCenter);
    float dotRadius = cellSize * animatedDotSize * 0.3;
    
    // Create perfect circle
    float dot = 1.0 - smoothstep(dotRadius - 1.0, dotRadius + 1.0, distanceToCenter);
    
    // Brightness based on pulse and distance from center
    float brightness = pulseEffect * (1.2 - distFromScreenCenter * 0.6);
    
    // Create colors based on toggle
    float3 finalColor;
    if (colorEnabled > 0.5) {
        finalColor = createGradientColor(colorHue, brightness, distFromScreenCenter);
    } else {
        finalColor = float3(brightness);
    }
    
    return half4(half3(finalColor * dot), color.a);
}

// PATTERN 3: Galactic Spiral Vortex
[[ stitchable ]] half4 dotGridRipple(float2 position, half4 color, float2 size, float time, float density, float dotSize, float colorHue, float colorEnabled) {
    float gridSize = mix(14.0, 32.0, density);
    float cellSize = min(size.x, size.y) / gridSize;
    
    float2 gridCoord = floor(position / cellSize);
    float2 cellCenter = (gridCoord + 0.5) * cellSize;
    
    // Center point for spiral (screen center)
    float2 screenCenter = size * 0.5;
    float2 centerOffset = position - screenCenter;
    float distFromCenter = length(centerOffset) / min(size.x, size.y);
    float angle = atan2(centerOffset.y, centerOffset.x);
    
    // Create spiral arms effect
    float spiral = sin(distFromCenter * 20.0 - angle * 4.0 - time * 5.0) * 0.5 + 0.5;
    
    // Add rotating galaxy arms
    float arms = sin(angle * 6.0 + time * 1.8) * 0.4 + 0.6;
    
    // Create depth effect
    float depth = 1.0 - smoothstep(0.0, 0.7, distFromCenter);
    
    // Combine effects
    float spiralEffect = spiral * arms * depth;
    
    // Animated dot size based on spiral intensity
    float animatedDotSize = dotSize * (0.6 + spiralEffect * 0.7);
    
    // Distance from position to cell center
    float distanceToCenter = length(position - cellCenter);
    float dotRadius = cellSize * animatedDotSize * 0.25;
    
    // Create perfect circle
    float dot = 1.0 - smoothstep(dotRadius - 1.0, dotRadius + 1.0, distanceToCenter);
    
    // Brightness with spiral pattern and center glow
    float centerGlow = 1.0 - smoothstep(0.0, 0.4, distFromCenter);
    float brightness = 0.3 + spiralEffect * 0.7 + centerGlow * 0.3;
    
    // Create colors based on toggle
    float3 finalColor;
    if (colorEnabled > 0.5) {
        float spiralHue = colorHue + angle * 0.1 + time * 0.1;
        finalColor = createGradientColor(spiralHue, brightness, spiralEffect);
    } else {
        finalColor = float3(brightness);
    }
    
    return half4(half3(finalColor * dot), color.a);
}

// PATTERN 4: Digital Matrix Rain
[[ stitchable ]] half4 dotGridNoise(float2 position, half4 color, float2 size, float time, float density, float dotSize, float colorHue, float colorEnabled) {
    float gridSize = mix(18.0, 40.0, density);
    float cellSize = min(size.x, size.y) / gridSize;
    
    float2 gridCoord = floor(position / cellSize);
    float2 cellCenter = (gridCoord + 0.5) * cellSize;
    
    // Normalized coordinates for effects
    float2 normalizedPos = position / size;
    
    // Create matrix-like falling effect
    float columnOffset = hash(float2(gridCoord.x, 0.0)) * 10.0;
    float fallSpeed = 3.0;
    float yPos = fract((normalizedPos.y + time * fallSpeed * 0.1 + columnOffset) * 0.5);
    
    // Random brightness per column
    float columnBrightness = hash(float2(gridCoord.x, floor(time * 3.0 + columnOffset)));
    
    // Create digital trails
    float trail = 1.0 - smoothstep(0.0, 0.9, yPos);
    trail = pow(trail, 1.5);
    
    // Random dot visibility
    float randomVisibility = smoothNoise(gridCoord + time * 2.0);
    randomVisibility = smoothstep(0.3, 0.95, randomVisibility);
    
    // Add glitch effects
    float glitch = sin(time * 10.0 + hash(gridCoord) * 100.0);
    glitch = smoothstep(0.95, 1.0, glitch) * 0.5;
    
    // Distance from position to cell center
    float distanceToCenter = length(position - cellCenter);
    float dotRadius = cellSize * dotSize * 0.3;
    
    // Create perfect circle
    float dot = 1.0 - smoothstep(dotRadius - 1.0, dotRadius + 1.0, distanceToCenter);
    
    // Final brightness combining all effects
    float brightness = (trail * columnBrightness * randomVisibility + glitch) * 0.9;
    brightness = min(brightness, 1.0);
    
    // Create colors based on toggle
    float3 finalColor;
    if (colorEnabled > 0.5) {
        float digitalHue = colorHue + gridCoord.y * 0.01 + trail * 0.2;
        finalColor = createGradientColor(digitalHue, brightness, trail);
    } else {
        finalColor = float3(brightness);
    }
    
    return half4(half3(finalColor * dot), color.a);
}
