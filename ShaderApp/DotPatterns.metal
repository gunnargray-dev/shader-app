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

// Bloom effect function
float3 applyBloom(float3 color, float2 position, float2 size, float intensity, float radius) {
    if (intensity <= 0.0) return color;
    
    // Create a bloom kernel
    float2 normalizedPos = position / size;
    float2 center = float2(0.5);
    float distFromCenter = length(normalizedPos - center);
    
    // Create bloom glow
    float bloomSize = radius * 0.5;
    float bloomFalloff = 1.0 - smoothstep(0.0, bloomSize, distFromCenter);
    bloomFalloff = pow(bloomFalloff, 0.5);
    
    // Create additional bloom layers for more realistic effect
    float bloom1 = exp(-distFromCenter * 8.0 / bloomSize);
    float bloom2 = exp(-distFromCenter * 4.0 / bloomSize);
    float bloom3 = exp(-distFromCenter * 2.0 / bloomSize);
    
    float combinedBloom = (bloom1 * 0.5 + bloom2 * 0.3 + bloom3 * 0.2) * intensity;
    
    // Add bloom to the original color
    return color + color * combinedBloom;
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
[[ stitchable ]] half4 dotGridWave(float2 position, half4 color, float2 size, float time, float density, float dotSize, float colorHue, float colorEnabled, float bloomIntensity, float bloomRadius, float brightness) {
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
    
    // Enhanced color intensity with higher contrast
    float waveIntensity = sin(waveOffset * 2.0 + time);
    float intensity = 0.15 + 1.2 * (0.5 + 0.5 * waveIntensity);
    
    // Apply contrast enhancement
    intensity = pow(intensity, 1.5); // Gamma correction for more punch
    intensity = clamp(intensity, 0.0, 1.4);
    
    // Apply brightness multiplier
    intensity *= brightness;
    
    // Create colors based on toggle
    float3 finalColor;
    if (colorEnabled > 0.5) {
        finalColor = createGradientColor(colorHue, intensity, waveOffset);
    } else {
        finalColor = float3(intensity);
    }
    
    // Apply bloom effect
    finalColor = applyBloom(finalColor, position, size, bloomIntensity, bloomRadius);
    
    return half4(half3(finalColor * dot), color.a);
}

// PATTERN 2: Hypnotic Breathing Pulse
[[ stitchable ]] half4 dotGridPulse(float2 position, half4 color, float2 size, float time, float density, float dotSize, float colorHue, float colorEnabled, float bloomIntensity, float bloomRadius, float brightness) {
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
    
    // Enhanced brightness with higher contrast
    float pulseBrightness = pulseEffect * (1.8 - distFromScreenCenter * 0.8);
    
    // Apply aggressive contrast enhancement
    pulseBrightness = pow(pulseBrightness, 2.0); // Strong gamma for dramatic effect
    pulseBrightness = clamp(pulseBrightness, 0.05, 1.6);
    
    // Apply brightness multiplier
    pulseBrightness *= brightness;
    
    // Create colors based on toggle
    float3 finalColor;
    if (colorEnabled > 0.5) {
        finalColor = createGradientColor(colorHue, pulseBrightness, distFromScreenCenter);
    } else {
        finalColor = float3(pulseBrightness);
    }
    
    // Apply bloom effect
    finalColor = applyBloom(finalColor, position, size, bloomIntensity, bloomRadius);
    
    return half4(half3(finalColor * dot), color.a);
}

// PATTERN 3: Galactic Spiral Vortex
[[ stitchable ]] half4 dotGridRipple(float2 position, half4 color, float2 size, float time, float density, float dotSize, float colorHue, float colorEnabled, float bloomIntensity, float bloomRadius, float brightness) {
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
    
    // Enhanced brightness with dramatic spiral contrast
    float centerGlow = 1.0 - smoothstep(0.0, 0.4, distFromCenter);
    float spiralBrightness = 0.1 + spiralEffect * 1.3 + centerGlow * 0.6;
    
    // Apply strong contrast enhancement for spiral definition
    spiralBrightness = pow(spiralBrightness, 1.8); // Strong gamma for spiral clarity
    spiralBrightness = clamp(spiralBrightness, 0.0, 1.7);
    
    // Apply brightness multiplier
    spiralBrightness *= brightness;
    
    // Create colors based on toggle
    float3 finalColor;
    if (colorEnabled > 0.5) {
        float spiralHue = colorHue + angle * 0.1 + time * 0.1;
        finalColor = createGradientColor(spiralHue, spiralBrightness, spiralEffect);
    } else {
        finalColor = float3(spiralBrightness);
    }
    
    // Apply bloom effect
    finalColor = applyBloom(finalColor, position, size, bloomIntensity, bloomRadius);
    
    return half4(half3(finalColor * dot), color.a);
}

// PATTERN 4: Digital Matrix Rain
[[ stitchable ]] half4 dotGridNoise(float2 position, half4 color, float2 size, float time, float density, float dotSize, float colorHue, float colorEnabled, float bloomIntensity, float bloomRadius, float brightness) {
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
    
    // Enhanced brightness with dramatic digital contrast
    float digitalBrightness = (trail * columnBrightness * randomVisibility + glitch) * 1.4;
    
    // Apply strong contrast for digital matrix effect
    digitalBrightness = pow(digitalBrightness, 2.2); // Strong gamma for digital clarity
    digitalBrightness = clamp(digitalBrightness, 0.02, 1.8);
    
    // Apply brightness multiplier
    digitalBrightness *= brightness;
    
    // Create colors based on toggle
    float3 finalColor;
    if (colorEnabled > 0.5) {
        float digitalHue = colorHue + gridCoord.y * 0.01 + trail * 0.2;
        finalColor = createGradientColor(digitalHue, digitalBrightness, trail);
    } else {
        finalColor = float3(digitalBrightness);
    }
    
    // Apply bloom effect
    finalColor = applyBloom(finalColor, position, size, bloomIntensity, bloomRadius);
    
    return half4(half3(finalColor * dot), color.a);
}

// Helper function for cellular noise
float2 random2(float2 p) {
    return fract(sin(float2(
        dot(p, float2(127.1, 311.7)),
        dot(p, float2(269.5, 183.3))
    )) * 43758.5453);
}

// PATTERN 5: Cellular Voronoi Noise
[[ stitchable ]] half4 dotGridCellular(float2 position, half4 color, float2 size, float time, float density, float dotSize, float colorHue, float colorEnabled, float bloomIntensity, float bloomRadius, float brightness) {
    float gridSize = mix(15.0, 35.0, density);
    float cellSize = min(size.x, size.y) / gridSize;
    
    float2 gridCoord = floor(position / cellSize);
    float2 cellCenter = (gridCoord + 0.5) * cellSize;
    
    // Normalized coordinates for cellular noise calculation
    float2 st = position / size * 6.0; // Scale factor for cellular noise
    float2 i_st = floor(st);
    float2 f_st = fract(st);
    
    float m_dist = 1.0;
    float2 m_point = float2(0.0);
    
    // 3x3 cell iteration for Voronoi pattern
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            float2 neighbor = float2(x, y);
            float2 point = random2(i_st + neighbor);
            
            // Animate the cellular points
            point = 0.5 + 0.5 * sin(time * 0.8 + 6.2831 * point);
            
            float2 diff = neighbor + point - f_st;
            float dist = length(diff);
            
            if (dist < m_dist) {
                m_dist = dist;
                m_point = point;
            }
        }
    }
    
    // Create cellular pattern effect on dot size
    float cellularEffect = m_dist;
    
    // Add subtle animation and variation
    float cellularNoise = sin(m_point.x * 10.0 + time) * sin(m_point.y * 10.0 + time * 1.3);
    cellularEffect += cellularNoise * 0.3;
    
    // Create organic pulsing based on cellular distance
    float pulsing = sin(cellularEffect * 15.0 + time * 2.0) * 0.4 + 0.6;
    
    // Animated dot size based on cellular noise
    float animatedDotSize = dotSize * (0.5 + cellularEffect * 0.8) * pulsing;
    
    // Distance from position to cell center
    float distanceToCenter = length(position - cellCenter);
    float dotRadius = cellSize * animatedDotSize * 0.35;
    
    // Create perfect circle
    float dot = 1.0 - smoothstep(dotRadius - 1.0, dotRadius + 1.0, distanceToCenter);
    
    // Enhanced brightness with organic cellular contrast
    float cellularBrightness = 0.2 + cellularEffect * 1.1 + sin(cellularEffect * 8.0 + time * 1.5) * 0.5;
    
    // Apply contrast enhancement for cellular definition
    cellularBrightness = pow(cellularBrightness, 1.6); // Medium gamma for organic feel
    cellularBrightness = clamp(cellularBrightness, 0.0, 1.5);
    
    // Apply brightness multiplier
    cellularBrightness *= brightness;
    
    // Create colors based on toggle
    float3 finalColor;
    if (colorEnabled > 0.5) {
        // Create organic color variations based on cellular pattern
        float cellularHue = colorHue + m_point.x * 0.2 + m_point.y * 0.1;
        finalColor = createGradientColor(cellularHue, cellularBrightness, cellularEffect);
    } else {
        finalColor = float3(cellularBrightness);
    }
    
    // Apply bloom effect
    finalColor = applyBloom(finalColor, position, size, bloomIntensity, bloomRadius);
    
    return half4(half3(finalColor * dot), color.a);
}

// Enhanced flow field noise functions
float2 flowFieldNoise(float2 p) {
    // Create flow vectors using noise derivatives
    float epsilon = 0.01;
    float n1 = smoothNoise(p + float2(epsilon, 0.0));
    float n2 = smoothNoise(p - float2(epsilon, 0.0));
    float n3 = smoothNoise(p + float2(0.0, epsilon));
    float n4 = smoothNoise(p - float2(0.0, epsilon));
    
    float2 gradient = float2(n1 - n2, n3 - n4) / (2.0 * epsilon);
    return normalize(gradient);
}

float flowFieldStrength(float2 p, float time) {
    // Multi-octave noise for complex flow patterns
    float strength = 0.0;
    float amplitude = 1.0;
    float frequency = 1.0;
    
    for (int i = 0; i < 4; i++) {
        strength += amplitude * smoothNoise(p * frequency + time * 0.1);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    
    return strength * 0.5 + 0.5; // Normalize to 0-1
}

// PATTERN 6: Organic Flow Field
[[ stitchable ]] half4 dotGridFlowField(float2 position, half4 color, float2 size, float time, float density, float dotSize, float colorHue, float colorEnabled, float bloomIntensity, float bloomRadius, float brightness) {
    float gridSize = mix(16.0, 38.0, density);
    float cellSize = min(size.x, size.y) / gridSize;
    
    float2 gridCoord = floor(position / cellSize);
    float2 cellCenter = (gridCoord + 0.5) * cellSize;
    
    // Normalized coordinates for flow field calculation
    float2 flowPos = position / min(size.x, size.y) * 8.0; // Scale for flow field
    
    // Calculate flow vectors and strength
    float2 flowVector = flowFieldNoise(flowPos + time * 0.3);
    float flowStrength = flowFieldStrength(flowPos, time);
    
    // Add multiple flow layers for complexity
    float2 flowVector2 = flowFieldNoise(flowPos * 1.7 + time * 0.2 + float2(100.0, 50.0));
    float flowStrength2 = flowFieldStrength(flowPos * 1.3 + time * 0.15, time);
    
    // Combine flow layers
    float2 combinedFlow = (flowVector * flowStrength + flowVector2 * flowStrength2 * 0.6) / 1.6;
    float combinedStrength = (flowStrength + flowStrength2) * 0.5;
    
    // Create swirling motion
    float swirl = sin(time * 1.5 + length(flowPos) * 3.0) * 0.3;
    float cosSwirl = cos(swirl);
    float sinSwirl = sin(swirl);
    float2 rotatedFlow = float2(
        combinedFlow.x * cosSwirl - combinedFlow.y * sinSwirl,
        combinedFlow.x * sinSwirl + combinedFlow.y * cosSwirl
    );
    
    // Apply flow-based offset to cell center
    float2 flowOffset = rotatedFlow * cellSize * 0.3 * combinedStrength;
    float2 flowCenter = cellCenter + flowOffset;
    
    // Distance from position to flow-adjusted center
    float distanceToCenter = length(position - flowCenter);
    
    // Dynamic dot size based on flow strength and convergence
    float convergence = 1.0 - length(combinedFlow); // Higher when flow converges
    float flowDotSize = dotSize * (0.6 + combinedStrength * 0.7 + convergence * 0.4);
    
    // Add pulsing based on flow direction
    float directionPulse = sin(atan2(rotatedFlow.y, rotatedFlow.x) * 4.0 + time * 2.0) * 0.2 + 0.8;
    flowDotSize *= directionPulse;
    
    float dotRadius = cellSize * flowDotSize * 0.35;
    
    // Create perfect circle with soft edges
    float dot = 1.0 - smoothstep(dotRadius - 2.0, dotRadius + 2.0, distanceToCenter);
    
    // Enhanced brightness with dynamic flow contrast
    float flowBrightness = 0.2 + combinedStrength * 1.0 + convergence * 0.6;
    
    // Add flowing highlights with higher intensity
    float highlight = sin(combinedStrength * 10.0 + time * 3.0) * 0.4 + 0.8;
    flowBrightness *= highlight;
    
    // Apply contrast enhancement for flow definition
    flowBrightness = pow(flowBrightness, 1.4); // Medium gamma for flow clarity
    flowBrightness = clamp(flowBrightness, 0.0, 1.6);
    
    // Apply brightness multiplier
    flowBrightness *= brightness;
    
    // Create colors based on toggle
    float3 finalColor;
    if (colorEnabled > 0.5) {
        // Color variations based on flow direction and strength
        float flowHue = colorHue + atan2(rotatedFlow.y, rotatedFlow.x) * 0.1 + combinedStrength * 0.15;
        finalColor = createGradientColor(flowHue, flowBrightness, combinedStrength);
    } else {
        finalColor = float3(flowBrightness);
    }
    
    // Apply bloom effect
    finalColor = applyBloom(finalColor, position, size, bloomIntensity, bloomRadius);
    
    return half4(half3(finalColor * dot), color.a);
}

// Gravity simulation functions
struct GravityWell {
    float2 position;
    float mass;
    float influence;
};

GravityWell createGravityWell(float2 screenSize, float time, int index) {
    GravityWell well;
    
    // Create different orbital patterns for each gravity well
    float offset = float(index) * 2.094; // Roughly 2π/3 for good separation
    float radius = 0.25 + sin(time * 0.3 + offset) * 0.15; // Varying orbital radius
    float speed = 0.8 + float(index) * 0.2; // Different speeds
    
    // Orbital motion around screen center
    float angle = time * speed + offset;
    float2 center = screenSize * 0.5;
    well.position = center + float2(
        cos(angle) * radius * min(screenSize.x, screenSize.y),
        sin(angle * 1.3) * radius * min(screenSize.x, screenSize.y) // Elliptical orbit
    );
    
    // Varying mass over time
    well.mass = 0.8 + sin(time * 1.5 + offset * 2.0) * 0.4;
    well.influence = 0.3 + well.mass * 0.2;
    
    return well;
}

float2 calculateGravitationalForce(float2 position, GravityWell well) {
    float2 direction = well.position - position;
    float distance = length(direction);
    
    // Prevent division by zero and extreme forces
    distance = max(distance, 10.0);
    
    // Simplified inverse square law
    float force = well.mass * well.influence / (distance * distance * 0.001);
    
    // Limit maximum force to prevent instability
    force = min(force, 2.0);
    
    return normalize(direction) * force;
}

// PATTERN 7: Physics-Based Gravity Simulation
[[ stitchable ]] half4 dotGridGravity(float2 position, half4 color, float2 size, float time, float density, float dotSize, float colorHue, float colorEnabled, float bloomIntensity, float bloomRadius, float brightness) {
    float gridSize = mix(14.0, 32.0, density);
    float cellSize = min(size.x, size.y) / gridSize;
    
    float2 gridCoord = floor(position / cellSize);
    float2 cellCenter = (gridCoord + 0.5) * cellSize;
    
    // Create multiple gravity wells
    GravityWell well1 = createGravityWell(size, time, 0);
    GravityWell well2 = createGravityWell(size, time, 1);
    GravityWell well3 = createGravityWell(size, time, 2);
    
    // Calculate total gravitational force
    float2 totalForce = float2(0.0);
    totalForce += calculateGravitationalForce(cellCenter, well1);
    totalForce += calculateGravitationalForce(cellCenter, well2);
    totalForce += calculateGravitationalForce(cellCenter, well3);
    
    // Apply gravitational displacement to dot position
    float2 gravityOffset = totalForce * cellSize * 0.8;
    float2 attractedCenter = cellCenter + gravityOffset;
    
    // Distance from position to gravity-affected center
    float distanceToCenter = length(position - attractedCenter);
    
    // Calculate proximity to gravity wells for size and brightness effects
    float proximity1 = 1.0 / (1.0 + length(position - well1.position) / 100.0);
    float proximity2 = 1.0 / (1.0 + length(position - well2.position) / 100.0);
    float proximity3 = 1.0 / (1.0 + length(position - well3.position) / 100.0);
    float totalProximity = (proximity1 * well1.mass + proximity2 * well2.mass + proximity3 * well3.mass) / 3.0;
    
    // Dynamic dot size based on gravitational effects
    float forceStrength = length(totalForce);
    float gravityDotSize = dotSize * (0.5 + totalProximity * 1.2 + forceStrength * 0.3);
    
    // Add orbital velocity effects (perpendicular to force)
    float2 perpForce = float2(-totalForce.y, totalForce.x);
    float orbitalInfluence = sin(time * 2.0 + length(totalForce) * 5.0) * 0.3;
    gravityDotSize *= (1.0 + orbitalInfluence);
    
    float dotRadius = cellSize * gravityDotSize * 0.35;
    
    // Create perfect circle with gravity-influenced soft edges
    float softness = 1.0 + totalProximity * 2.0; // Softer edges near gravity wells
    float dot = 1.0 - smoothstep(dotRadius - softness, dotRadius + softness, distanceToCenter);
    
    // Enhanced brightness with dramatic gravitational contrast
    float gravityBrightness = 0.15 + totalProximity * 1.3 + forceStrength * 0.7;
    
    // Add energy emissions near gravity wells with higher intensity
    float energyPulse = sin(totalProximity * 20.0 + time * 4.0) * 0.5 + 0.7;
    gravityBrightness *= energyPulse;
    
    // Enhanced tidal effects for better visibility
    float tidalEffect = sin(forceStrength * 8.0 + time * 3.0) * 0.4 + 0.8;
    gravityBrightness *= tidalEffect;
    
    // Apply strong contrast for gravitational field definition
    gravityBrightness = pow(gravityBrightness, 1.7); // Strong gamma for gravity clarity
    gravityBrightness = clamp(gravityBrightness, 0.0, 1.8);
    
    // Apply brightness multiplier
    gravityBrightness *= brightness;
    
    // Create colors based on toggle
    float3 finalColor;
    if (colorEnabled > 0.5) {
        // Color shifts based on gravitational field properties
        float fieldHue = colorHue + totalProximity * 0.3 + atan2(totalForce.y, totalForce.x) * 0.1;
        
        // Energy color shifts near gravity wells
        float energyShift = (proximity1 + proximity2 + proximity3) * 0.2;
        fieldHue += energyShift;
        
        finalColor = createGradientColor(fieldHue, gravityBrightness, totalProximity + forceStrength);
    } else {
        finalColor = float3(gravityBrightness);
    }
    
    // Apply bloom effect
    finalColor = applyBloom(finalColor, position, size, bloomIntensity, bloomRadius);
    
    return half4(half3(finalColor * dot), color.a);
}

// Complex number operations for fractal mathematics
struct Complex {
    float real;
    float imag;
};

Complex complexAdd(Complex a, Complex b) {
    Complex result;
    result.real = a.real + b.real;
    result.imag = a.imag + b.imag;
    return result;
}

Complex complexMul(Complex a, Complex b) {
    Complex result;
    result.real = a.real * b.real - a.imag * b.imag;
    result.imag = a.real * b.imag + a.imag * b.real;
    return result;
}

float complexMagnitudeSquared(Complex z) {
    return z.real * z.real + z.imag * z.imag;
}

// Julia set iteration function
int juliaIteration(Complex z, Complex c, int maxIterations) {
    for (int i = 0; i < maxIterations; i++) {
        if (complexMagnitudeSquared(z) > 4.0) {
            return i;
        }
        z = complexAdd(complexMul(z, z), c);
    }
    return maxIterations;
}

// Smooth iteration count for better gradients
float smoothJuliaIteration(Complex z, Complex c, int maxIterations) {
    for (int i = 0; i < maxIterations; i++) {
        float magnitude = complexMagnitudeSquared(z);
        if (magnitude > 4.0) {
            // Smooth iteration count using logarithmic interpolation
            return float(i) + 1.0 - log2(log2(magnitude)) / log2(2.0);
        }
        z = complexAdd(complexMul(z, z), c);
    }
    return float(maxIterations);
}

// PATTERN 8: Mathematical Julia Set Fractal
[[ stitchable ]] half4 dotGridFractal(float2 position, half4 color, float2 size, float time, float density, float dotSize, float colorHue, float colorEnabled, float bloomIntensity, float bloomRadius, float brightness) {
    float gridSize = mix(18.0, 45.0, density);
    float cellSize = min(size.x, size.y) / gridSize;
    
    float2 gridCoord = floor(position / cellSize);
    float2 cellCenter = (gridCoord + 0.5) * cellSize;
    
    // Create animated zoom effect
    float zoomFactor = 1.5 + sin(time * 0.3) * 0.8;
    float2 zoomCenter = size * 0.5 + float2(
        sin(time * 0.2) * size.x * 0.1,
        cos(time * 0.15) * size.y * 0.1
    );
    
    // Convert position to complex plane coordinates
    float2 fractalPos = (position - zoomCenter) / (min(size.x, size.y) * zoomFactor);
    Complex z;
    z.real = fractalPos.x * 3.0; // Scale to interesting fractal region
    z.imag = fractalPos.y * 3.0;
    
    // Animated Julia set parameter
    Complex c;
    c.real = -0.7 + sin(time * 0.5) * 0.3;
    c.imag = 0.27015 + cos(time * 0.7) * 0.2;
    
    // Alternative interesting Julia parameters (can be switched)
    if (sin(time * 0.1) > 0.0) {
        c.real = -0.8 + sin(time * 0.3) * 0.2;
        c.imag = 0.156 + cos(time * 0.4) * 0.15;
    }
    
    // Calculate fractal iteration count
    int maxIterations = 32; // Balanced for performance and detail
    float iterations = smoothJuliaIteration(z, c, maxIterations);
    
    // Normalize iteration count
    float fractalValue = iterations / float(maxIterations);
    
    // Create fractal-based effects
    float isInSet = (iterations >= float(maxIterations)) ? 1.0 : 0.0;
    float escapeSpeed = 1.0 - fractalValue;
    
    // Dynamic dot size based on fractal properties
    float fractalDotSize = dotSize;
    
    if (isInSet > 0.5) {
        // Points in the set - larger, stable dots
        fractalDotSize *= (1.2 + sin(time * 2.0 + length(fractalPos) * 10.0) * 0.3);
    } else {
        // Points outside the set - size based on escape speed
        fractalDotSize *= (0.4 + escapeSpeed * 0.8 + sin(iterations * 0.5 + time * 3.0) * 0.2);
    }
    
    // Add fractal detail pulsing
    float detailPulse = sin(iterations * 2.0 + time * 4.0) * 0.2 + 0.8;
    fractalDotSize *= detailPulse;
    
    // Distance from position to cell center
    float distanceToCenter = length(position - cellCenter);
    float dotRadius = cellSize * fractalDotSize * 0.35;
    
    // Create perfect circle with fractal-influenced edges
    float dot = 1.0 - smoothstep(dotRadius - 1.5, dotRadius + 1.5, distanceToCenter);
    
    // Enhanced brightness with dramatic fractal contrast
    float fractalBrightness;
    if (isInSet > 0.5) {
        // Points in the set - deep, rich colors with high contrast
        fractalBrightness = 1.2 + sin(time * 1.5 + length(fractalPos) * 8.0) * 0.6;
    } else {
        // Points outside the set - dramatic gradient based on escape time
        fractalBrightness = 0.05 + escapeSpeed * 1.5;
        
        // Enhanced banding effects for better definition
        float bands = sin(iterations * 1.5) * 0.6 + 0.7;
        fractalBrightness *= bands;
    }
    
    // Enhanced fractal edge enhancement for sharp detail
    float edgeDetection = abs(sin(iterations * 3.14159)) * 0.7 + 0.6;
    fractalBrightness *= edgeDetection;
    
    // Apply strong contrast for fractal mathematics clarity
    fractalBrightness = pow(fractalBrightness, 1.6); // Strong gamma for mathematical precision
    fractalBrightness = clamp(fractalBrightness, 0.0, 2.0);
    
    // Apply brightness multiplier
    fractalBrightness *= brightness;
    
    // Create colors based on toggle
    float3 finalColor;
    if (colorEnabled > 0.5) {
        if (isInSet > 0.5) {
            // Inside set - deep, saturated colors
            float setHue = colorHue + sin(time * 0.8) * 0.1;
            finalColor = createGradientColor(setHue, fractalBrightness, 0.8);
        } else {
            // Outside set - rainbow spectrum based on iteration count
            float escapeHue = colorHue + fractalValue * 0.8 + sin(iterations * 0.3) * 0.2;
            finalColor = createGradientColor(escapeHue, fractalBrightness, escapeSpeed);
        }
        
        // Add mathematical beauty enhancement
        float mathematicalGlow = sin(iterations * 0.7 + time) * 0.15 + 0.85;
        finalColor *= mathematicalGlow;
    } else {
        finalColor = float3(fractalBrightness);
    }
    
    // Apply bloom effect
    finalColor = applyBloom(finalColor, position, size, bloomIntensity, bloomRadius);
    
    return half4(half3(finalColor * dot), color.a);
}

// Kaleidoscope symmetry functions
float2 polarToCartesian(float radius, float angle) {
    return float2(radius * cos(angle), radius * sin(angle));
}

float2 cartesianToPolar(float2 pos) {
    return float2(length(pos), atan2(pos.y, pos.x));
}

float2 kaleidoscopeReflection(float2 position, float numSegments, float time) {
    // Convert to polar coordinates
    float2 polar = cartesianToPolar(position);
    float radius = polar.x;
    float angle = polar.y;
    
    // Create symmetrical segments
    float segmentAngle = 2.0 * 3.14159 / numSegments;
    
    // Normalize angle to [0, 2π]
    angle = fmod(angle + 3.14159, 2.0 * 3.14159);
    
    // Find which segment we're in
    float segmentIndex = floor(angle / segmentAngle);
    float angleInSegment = angle - segmentIndex * segmentAngle;
    
    // Apply reflection for kaleidoscope effect
    bool shouldReflect = int(segmentIndex) % 2 == 1;
    if (shouldReflect) {
        angleInSegment = segmentAngle - angleInSegment;
    }
    
    // Add gentle rotation for meditation
    float rotation = time * 0.1;
    angleInSegment += rotation;
    
    // Convert back to cartesian
    return polarToCartesian(radius, angleInSegment);
}

float2 createMandalaPattern(float2 position, float time) {
    // Apply multiple levels of symmetry for complex mandalas
    float2 level1 = kaleidoscopeReflection(position, 8.0, time);
    float2 level2 = kaleidoscopeReflection(level1 * 0.7, 6.0, time * 1.3);
    
    // Combine symmetry levels
    return level1 * 0.6 + level2 * 0.4;
}

// PATTERN 9: Symmetrical Kaleidoscope Mandala
[[ stitchable ]] half4 dotGridKaleidoscope(float2 position, half4 color, float2 size, float time, float density, float dotSize, float colorHue, float colorEnabled, float bloomIntensity, float bloomRadius, float brightness) {
    float gridSize = mix(16.0, 40.0, density);
    float cellSize = min(size.x, size.y) / gridSize;
    
    float2 gridCoord = floor(position / cellSize);
    float2 cellCenter = (gridCoord + 0.5) * cellSize;
    
    // Center the kaleidoscope
    float2 screenCenter = size * 0.5;
    float2 centeredPos = position - screenCenter;
    
    // Normalize to create symmetrical patterns
    float2 normalizedPos = centeredPos / (min(size.x, size.y) * 0.5);
    
    // Apply kaleidoscope transformation
    float2 kaleidoPos = createMandalaPattern(normalizedPos, time);
    
    // Create base pattern using the reflected coordinates
    float2 patternCoord = kaleidoPos * 4.0 + time * 0.2;
    
    // Generate underlying pattern using smooth noise and waves
    float pattern1 = smoothNoise(patternCoord);
    float pattern2 = sin(length(kaleidoPos) * 10.0 + time * 2.0);
    float pattern3 = cos(kaleidoPos.x * 8.0 + kaleidoPos.y * 6.0 + time * 1.5);
    
    // Combine patterns for rich mandala texture
    float combinedPattern = (pattern1 + pattern2 * 0.5 + pattern3 * 0.3) / 1.8;
    
    // Add radial structure for mandala effect
    float radius = length(normalizedPos);
    float radialPattern = sin(radius * 15.0 + time) * 0.3 + 0.7;
    
    // Create angular segments for kaleidoscope effect
    float angle = atan2(normalizedPos.y, normalizedPos.x);
    float angularPattern = sin(angle * 6.0 + time * 0.5) * 0.2 + 0.8;
    
    // Combine all patterns
    float mandalaIntensity = combinedPattern * radialPattern * angularPattern;
    mandalaIntensity = (mandalaIntensity + 1.0) * 0.5; // Normalize to [0,1]
    
    // Dynamic dot size based on mandala intensity
    float kaleidoDotSize = dotSize * (0.6 + mandalaIntensity * 0.8);
    
    // Add breathing effect for meditation
    float breathingEffect = sin(time * 0.8) * 0.2 + 0.8;
    kaleidoDotSize *= breathingEffect;
    
    // Add detail pulsing synchronized with pattern
    float detailPulse = sin(mandalaIntensity * 8.0 + time * 3.0) * 0.2 + 0.8;
    kaleidoDotSize *= detailPulse;
    
    // Distance from position to cell center
    float distanceToCenter = length(position - cellCenter);
    float dotRadius = cellSize * kaleidoDotSize * 0.35;
    
    // Create perfect circle with soft meditative edges
    float softness = 1.5 + mandalaIntensity; // Softer edges enhance the meditative quality
    float dot = 1.0 - smoothstep(dotRadius - softness, dotRadius + softness, distanceToCenter);
    
    // Enhanced brightness with dramatic mandala contrast
    float kaleidoBrightness = 0.2 + mandalaIntensity * 1.2;
    
    // Enhanced center glow for stronger focus point
    float centerGlow = 1.0 - smoothstep(0.0, 0.6, radius);
    kaleidoBrightness += centerGlow * 0.6;
    
    // Enhanced symmetrical highlights for better definition
    float symmetryHighlight = sin(mandalaIntensity * 12.0 + time * 2.0) * 0.4 + 0.8;
    kaleidoBrightness *= symmetryHighlight;
    
    // Enhanced meditative pulsing
    float meditativePulse = sin(time * 0.4) * 0.2 + 0.9;
    kaleidoBrightness *= meditativePulse;
    
    // Apply contrast enhancement for kaleidoscope clarity
    kaleidoBrightness = pow(kaleidoBrightness, 1.3); // Medium gamma for mandala beauty
    kaleidoBrightness = clamp(kaleidoBrightness, 0.0, 1.8);
    
    // Apply brightness multiplier
    kaleidoBrightness *= brightness;
    
    // Create colors based on toggle
    float3 finalColor;
    if (colorEnabled > 0.5) {
        // Create rainbow mandala with symmetrical color distribution
        float symmetricalAngle = atan2(kaleidoPos.y, kaleidoPos.x);
        float colorAngle = symmetricalAngle + time * 0.1;
        
        // Base hue with radial and angular variations
        float mandalaHue = colorHue + sin(colorAngle * 3.0) * 0.2 + radius * 0.3;
        
        // Add color depth for mandala rings
        float ringEffect = sin(radius * 8.0 + time * 0.5) * 0.15;
        mandalaHue += ringEffect;
        
        finalColor = createGradientColor(mandalaHue, kaleidoBrightness, mandalaIntensity);
        
        // Add golden ratio harmonics for spiritual aesthetics
        float goldenHarmonic = sin(mandalaIntensity * 1.618 + time * 0.618) * 0.1 + 0.9;
        finalColor *= goldenHarmonic;
    } else {
        finalColor = float3(kaleidoBrightness);
    }
    
    // Apply bloom effect
    finalColor = applyBloom(finalColor, position, size, bloomIntensity, bloomRadius);
    
    return half4(half3(finalColor * dot), color.a);
}

// Magnetic field physics structures
struct MagneticPole {
    float2 position;
    float charge; // +1 for north pole, -1 for south pole
    float strength;
};

MagneticPole createMagneticPole(float2 screenSize, float time, int index, bool isNorth) {
    MagneticPole pole;
    
    // Create orbital motion for magnetic poles
    float offset = float(index) * 1.57; // π/2 for good separation
    float radius = 0.2 + sin(time * 0.4 + offset) * 0.1;
    float speed = 0.6 + float(index) * 0.3;
    
    // Different orbit patterns for north and south poles
    float angle = time * speed + offset;
    if (!isNorth) {
        angle += 3.14159; // π offset for opposite poles
        radius *= 0.8; // Slightly smaller orbit
    }
    
    float2 center = screenSize * 0.5;
    pole.position = center + float2(
        cos(angle) * radius * min(screenSize.x, screenSize.y),
        sin(angle * 1.2) * radius * min(screenSize.x, screenSize.y) * 0.7 // Elliptical orbit
    );
    
    pole.charge = isNorth ? 1.0 : -1.0;
    pole.strength = 0.8 + sin(time * 1.2 + offset) * 0.3;
    
    return pole;
}

float2 calculateMagneticField(float2 position, MagneticPole pole) {
    float2 r = position - pole.position;
    float distance = length(r);
    
    // Prevent singularities
    distance = max(distance, 5.0);
    
    // Simplified magnetic dipole field calculation
    // Real physics: B ∝ 1/r³, but we use 1/r² for visual appeal
    float fieldStrength = pole.charge * pole.strength / (distance * distance * 0.0001);
    
    // Limit field strength for stability
    fieldStrength = clamp(fieldStrength, -3.0, 3.0);
    
    // Field direction (simplified dipole field)
    float2 fieldDirection = normalize(r) * fieldStrength;
    
    return fieldDirection;
}

float calculateFieldLineIntensity(float2 position, MagneticPole northPole, MagneticPole southPole) {
    // Calculate field line density by tracing from north to south
    float2 toNorth = northPole.position - position;
    float2 toSouth = southPole.position - position;
    
    float distToNorth = length(toNorth);
    float distToSouth = length(toSouth);
    
    // Field lines are denser closer to poles
    float fieldLineDensity = 1.0 / (1.0 + distToNorth * 0.01) + 1.0 / (1.0 + distToSouth * 0.01);
    
    // Create field line pattern using the field direction
    float2 totalField = calculateMagneticField(position, northPole) + calculateMagneticField(position, southPole);
    float fieldAngle = atan2(totalField.y, totalField.x);
    
    // Create visible field lines
    float linePattern = sin(fieldAngle * 8.0 + length(totalField) * 20.0) * 0.5 + 0.5;
    
    return fieldLineDensity * linePattern;
}

// PATTERN 10: Magnetic Field Visualization
[[ stitchable ]] half4 dotGridMagnetic(float2 position, half4 color, float2 size, float time, float density, float dotSize, float colorHue, float colorEnabled, float bloomIntensity, float bloomRadius, float brightness) {
    float gridSize = mix(15.0, 35.0, density);
    float cellSize = min(size.x, size.y) / gridSize;
    
    float2 gridCoord = floor(position / cellSize);
    float2 cellCenter = (gridCoord + 0.5) * cellSize;
    
    // Create magnetic dipoles (north-south pole pairs)
    MagneticPole north1 = createMagneticPole(size, time, 0, true);
    MagneticPole south1 = createMagneticPole(size, time, 0, false);
    
    MagneticPole north2 = createMagneticPole(size, time, 1, true);
    MagneticPole south2 = createMagneticPole(size, time, 1, false);
    
    // Calculate total magnetic field at this position
    float2 totalField = float2(0.0);
    totalField += calculateMagneticField(cellCenter, north1);
    totalField += calculateMagneticField(cellCenter, south1);
    totalField += calculateMagneticField(cellCenter, north2);
    totalField += calculateMagneticField(cellCenter, south2);
    
    // Calculate field strength and direction
    float fieldStrength = length(totalField);
    float2 fieldDirection = normalize(totalField);
    
    // Apply magnetic field displacement to dots
    float2 magneticOffset = fieldDirection * fieldStrength * cellSize * 0.3;
    float2 magneticCenter = cellCenter + magneticOffset;
    
    // Calculate field line effects
    float fieldLine1 = calculateFieldLineIntensity(cellCenter, north1, south1);
    float fieldLine2 = calculateFieldLineIntensity(cellCenter, north2, south2);
    float totalFieldLines = (fieldLine1 + fieldLine2) * 0.5;
    
    // Dynamic dot size based on magnetic field properties
    float magneticDotSize = dotSize * (0.6 + fieldStrength * 0.8 + totalFieldLines * 0.4);
    
    // Add magnetic resonance effect
    float resonance = sin(fieldStrength * 10.0 + time * 4.0) * 0.2 + 0.8;
    magneticDotSize *= resonance;
    
    // Add field line pulsing
    float fieldPulse = sin(totalFieldLines * 15.0 + time * 3.0) * 0.3 + 0.7;
    magneticDotSize *= fieldPulse;
    
    // Distance from position to magnetic-influenced center
    float distanceToCenter = length(position - magneticCenter);
    float dotRadius = cellSize * magneticDotSize * 0.35;
    
    // Create perfect circle with magnetic field softness
    float magneticSoftness = 1.0 + fieldStrength * 0.5; // Field strength affects edge softness
    float dot = 1.0 - smoothstep(dotRadius - magneticSoftness, dotRadius + magneticSoftness, distanceToCenter);
    
    // Enhanced brightness with dramatic magnetic contrast
    float magneticBrightness = 0.15 + fieldStrength * 1.1 + totalFieldLines * 0.7;
    
    // Enhanced pole proximity glow for better visibility
    float poleGlow = 0.0;
    poleGlow += 1.0 / (1.0 + length(position - north1.position) / 50.0);
    poleGlow += 1.0 / (1.0 + length(position - south1.position) / 50.0);
    poleGlow += 1.0 / (1.0 + length(position - north2.position) / 50.0);
    poleGlow += 1.0 / (1.0 + length(position - south2.position) / 50.0);
    magneticBrightness += poleGlow * 0.4;
    
    // Enhanced magnetic flux visualization with higher contrast
    float flux = sin(fieldStrength * 6.0 + time * 2.5) * 0.4 + 0.8;
    magneticBrightness *= flux;
    
    // Apply contrast enhancement for magnetic field clarity
    magneticBrightness = pow(magneticBrightness, 1.5); // Strong gamma for field line definition
    magneticBrightness = clamp(magneticBrightness, 0.0, 1.7);
    
    // Apply brightness multiplier
    magneticBrightness *= brightness;
    
    // Create colors based on toggle
    float3 finalColor;
    if (colorEnabled > 0.5) {
        // Color based on magnetic field properties
        float fieldAngle = atan2(fieldDirection.y, fieldDirection.x);
        float magneticHue = colorHue + fieldAngle * 0.15 + fieldStrength * 0.2;
        
        // North pole influence (cooler colors)
        float northInfluence = 1.0 / (1.0 + length(position - north1.position) / 100.0);
        northInfluence += 1.0 / (1.0 + length(position - north2.position) / 100.0);
        
        // South pole influence (warmer colors)
        float southInfluence = 1.0 / (1.0 + length(position - south1.position) / 100.0);
        southInfluence += 1.0 / (1.0 + length(position - south2.position) / 100.0);
        
        // Shift hue based on pole proximity
        magneticHue += (northInfluence - southInfluence) * 0.2;
        
        finalColor = createGradientColor(magneticHue, magneticBrightness, fieldStrength + totalFieldLines);
        
        // Add magnetic shimmer effect
        float shimmer = sin(totalFieldLines * 12.0 + time * 5.0) * 0.1 + 0.9;
        finalColor *= shimmer;
    } else {
        finalColor = float3(magneticBrightness);
    }
    
    // Apply bloom effect
    finalColor = applyBloom(finalColor, position, size, bloomIntensity, bloomRadius);
    
    return half4(half3(finalColor * dot), color.a);
}

// Organic growth simulation structures
struct GrowthCenter {
    float2 position;
    float age;
    float energy;
    float branchingAngle;
};

GrowthCenter createGrowthCenter(float2 screenSize, float time, int index) {
    GrowthCenter center;
    
    // Different starting positions for growth centers
    float offset = float(index) * 2.094; // Roughly 2π/3
    float startRadius = 0.15 + sin(time * 0.2 + offset) * 0.1;
    
    // Slowly moving growth origins
    float angle = time * 0.3 + offset;
    float2 screenCenter = screenSize * 0.5;
    center.position = screenCenter + float2(
        cos(angle) * startRadius * min(screenSize.x, screenSize.y),
        sin(angle * 0.8) * startRadius * min(screenSize.x, screenSize.y)
    );
    
    // Age determines how mature this growth center is
    center.age = fmod(time * 0.4 + offset, 10.0); // Cycle every 10 time units
    
    // Energy affects growth intensity
    center.energy = 0.7 + sin(time * 0.6 + offset * 2.0) * 0.3;
    
    // Branching angle for directional growth
    center.branchingAngle = time * 0.5 + offset;
    
    return center;
}

float calculateGrowthPattern(float2 position, GrowthCenter center, float time) {
    float2 toCenter = position - center.position;
    float distanceToCenter = length(toCenter);
    float angle = atan2(toCenter.y, toCenter.x);
    
    // Growth spreads outward over time
    float growthRadius = center.age * 50.0 * center.energy;
    
    // Basic growth field - exponential falloff
    float baseGrowth = exp(-distanceToCenter / max(growthRadius, 10.0));
    
    // Create branching patterns using noise and angular functions
    float branchingNoise = smoothNoise(position * 0.01 + center.branchingAngle);
    
    // Multiple branching directions
    float branch1 = sin(angle * 3.0 + center.branchingAngle) * 0.5 + 0.5;
    float branch2 = sin(angle * 5.0 + center.branchingAngle * 1.7) * 0.3 + 0.7;
    float branch3 = sin(angle * 7.0 + center.branchingAngle * 0.6) * 0.2 + 0.8;
    
    // Combine branching patterns
    float branchingPattern = (branch1 * branch2 * branch3) * (0.5 + branchingNoise * 0.5);
    
    // Add radial growth rings
    float ringPattern = sin(distanceToCenter * 0.1 - center.age * 2.0) * 0.3 + 0.7;
    
    // Create organic tree-like structure
    float treeStructure = baseGrowth * branchingPattern * ringPattern;
    
    return treeStructure;
}

float calculateCoralGrowth(float2 position, float time) {
    // Create coral-like spreading pattern using multiple octaves of noise
    float2 noisePos = position * 0.02 + time * 0.1;
    
    float coral = 0.0;
    float amplitude = 1.0;
    float frequency = 1.0;
    
    // Multi-octave noise for organic coral texture
    for (int i = 0; i < 4; i++) {
        coral += amplitude * smoothNoise(noisePos * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    
    // Add time-based growth waves
    float growthWave = sin(time * 0.8 + length(position) * 0.005) * 0.3 + 0.7;
    
    // Create coral density
    coral = (coral + 1.0) * 0.5 * growthWave;
    
    return coral;
}

float calculateVeinPattern(float2 position, float time) {
    // Create vein-like or root-like patterns
    float2 veinPos = position * 0.03;
    
    // Multiple vein directions
    float vein1 = abs(sin(veinPos.x * 2.0 + sin(veinPos.y * 1.5) + time * 0.5));
    float vein2 = abs(sin(veinPos.y * 2.0 + sin(veinPos.x * 1.8) + time * 0.3));
    float vein3 = abs(sin((veinPos.x + veinPos.y) * 1.5 + time * 0.7));
    
    // Combine veins with noise
    float veinNoise = smoothNoise(veinPos + time * 0.2);
    float veinPattern = (vein1 + vein2 + vein3) * (0.3 + veinNoise * 0.7) / 3.0;
    
    return veinPattern;
}

// PATTERN 11: Organic Growth Simulation
[[ stitchable ]] half4 dotGridGrowth(float2 position, half4 color, float2 size, float time, float density, float dotSize, float colorHue, float colorEnabled, float bloomIntensity, float bloomRadius, float brightness) {
    float gridSize = mix(16.0, 38.0, density);
    float cellSize = min(size.x, size.y) / gridSize;
    
    float2 gridCoord = floor(position / cellSize);
    float2 cellCenter = (gridCoord + 0.5) * cellSize;
    
    // Create multiple growth centers
    GrowthCenter center1 = createGrowthCenter(size, time, 0);
    GrowthCenter center2 = createGrowthCenter(size, time, 1);
    GrowthCenter center3 = createGrowthCenter(size, time, 2);
    
    // Calculate growth patterns from all centers
    float treeGrowth1 = calculateGrowthPattern(cellCenter, center1, time);
    float treeGrowth2 = calculateGrowthPattern(cellCenter, center2, time);
    float treeGrowth3 = calculateGrowthPattern(cellCenter, center3, time);
    
    // Combine tree-like growth patterns
    float totalTreeGrowth = (treeGrowth1 + treeGrowth2 + treeGrowth3) / 3.0;
    
    // Add coral-like spreading pattern
    float coralGrowth = calculateCoralGrowth(cellCenter, time);
    
    // Add vein/root patterns
    float veinGrowth = calculateVeinPattern(cellCenter, time);
    
    // Combine all growth types
    float combinedGrowth = totalTreeGrowth * 0.5 + coralGrowth * 0.3 + veinGrowth * 0.2;
    
    // Create growth emergence effect - dots appear based on growth timing
    float emergenceTime = fmod(time * 0.6, 8.0); // Growth cycles
    float distanceFromNearestCenter = min(
        length(cellCenter - center1.position),
        min(length(cellCenter - center2.position), length(cellCenter - center3.position))
    );
    
    // Growth spreads outward from centers over time
    float emergenceRadius = emergenceTime * 60.0;
    float emergenceFactor = 1.0 - smoothstep(emergenceRadius - 40.0, emergenceRadius + 40.0, distanceFromNearestCenter);
    
    // Apply emergence to growth pattern
    combinedGrowth *= emergenceFactor;
    
    // Dynamic dot size based on growth intensity
    float growthDotSize = dotSize * (0.4 + combinedGrowth * 1.2);
    
    // Add growth pulsing - like a heartbeat
    float growthPulse = sin(time * 1.5 + combinedGrowth * 8.0) * 0.2 + 0.8;
    growthDotSize *= growthPulse;
    
    // Add organic variation
    float organicVariation = smoothNoise(gridCoord * 0.1 + time * 0.3) * 0.3 + 0.7;
    growthDotSize *= organicVariation;
    
    // Distance from position to cell center
    float distanceToCenter = length(position - cellCenter);
    float dotRadius = cellSize * growthDotSize * 0.35;
    
    // Create perfect circle with organic softness
    float organicSoftness = 1.5 + combinedGrowth; // Growth makes edges softer
    float dot = 1.0 - smoothstep(dotRadius - organicSoftness, dotRadius + organicSoftness, distanceToCenter);
    
    // Enhanced brightness with organic growth contrast
    float growthBrightness = 0.1 + combinedGrowth * 1.4;
    
    // Enhanced growth center energy glow for better visibility
    float centerGlow = 0.0;
    centerGlow += center1.energy / (1.0 + length(position - center1.position) / 80.0);
    centerGlow += center2.energy / (1.0 + length(position - center2.position) / 80.0);
    centerGlow += center3.energy / (1.0 + length(position - center3.position) / 80.0);
    growthBrightness += centerGlow * 0.5;
    
    // Enhanced growth vitality pulsing
    float vitality = sin(combinedGrowth * 10.0 + time * 2.0) * 0.4 + 0.8;
    growthBrightness *= vitality;
    
    // Enhanced emergence effect for better definition
    growthBrightness *= (0.2 + emergenceFactor * 0.8);
    
    // Apply contrast enhancement for organic growth clarity
    growthBrightness = pow(growthBrightness, 1.4); // Medium gamma for organic beauty
    growthBrightness = clamp(growthBrightness, 0.0, 1.6);
    
    // Apply brightness multiplier
    growthBrightness *= brightness;
    
    // Create colors based on toggle
    float3 finalColor;
    if (colorEnabled > 0.5) {
        // Growth-based color evolution
        float growthAge = (center1.age + center2.age + center3.age) / 3.0;
        float growthHue = colorHue + growthAge * 0.1 + combinedGrowth * 0.3;
        
        // Young growth is greener, mature growth shifts toward brown/gold
        float maturityShift = sin(growthAge * 0.5) * 0.2;
        growthHue += maturityShift;
        
        // Add seasonal color variation
        float seasonalShift = sin(time * 0.1) * 0.15;
        growthHue += seasonalShift;
        
        finalColor = createGradientColor(growthHue, growthBrightness, combinedGrowth);
        
        // Add life force shimmer
        float lifeForce = sin(combinedGrowth * 15.0 + time * 4.0) * 0.1 + 0.9;
        finalColor *= lifeForce;
    } else {
        finalColor = float3(growthBrightness);
    }
    
    // Apply bloom effect
    finalColor = applyBloom(finalColor, position, size, bloomIntensity, bloomRadius);
    
    return half4(half3(finalColor * dot), color.a);
}

// 3D Tunnel coordinate transformation functions
struct TunnelCoords {
    float radius;        // Distance from tunnel center
    float angle;         // Angle around tunnel
    float depth;         // Depth into tunnel
    float perspective;   // Perspective scaling factor
};

TunnelCoords calculateTunnelCoords(float2 position, float2 screenSize, float time) {
    TunnelCoords coords;
    
    // Center the coordinates
    float2 center = screenSize * 0.5;
    float2 centeredPos = position - center;
    
    // Calculate radius and angle
    coords.radius = length(centeredPos) / (min(screenSize.x, screenSize.y) * 0.5);
    coords.angle = atan2(centeredPos.y, centeredPos.x);
    
    // More dramatic depth mapping - exaggerated tunnel effect
    coords.depth = 2.0 / (coords.radius + 0.05) + time * 3.0; // Faster, more dramatic
    
    // Much more dramatic perspective scaling
    coords.perspective = 1.0 / (1.0 + coords.depth * 0.3);
    
    return coords;
}

float calculateTunnelRings(TunnelCoords coords, float time) {
    // Create much more visible concentric rings
    float ringSpacing = 0.3; // Closer rings for more visible effect
    float ringPosition = fmod(coords.depth, ringSpacing);
    
    // Much more dramatic ring intensity
    float ringIntensity = sin(ringPosition * 2.0 * 3.14159 / ringSpacing);
    ringIntensity = ringIntensity * 0.8 + 0.2; // Higher contrast
    
    // Make rings much sharper and more visible
    float ringSharpness = 3.0 + sin(coords.depth * 2.0 + time * 3.0) * 1.0;
    ringIntensity = pow(abs(ringIntensity), 1.0 / ringSharpness);
    
    return ringIntensity;
}

float calculateTunnelSpiral(TunnelCoords coords, float time) {
    // Create spiral/vortex pattern in the tunnel
    float spiralTwist = coords.depth * 2.0 + time * 3.0; // Spiral tightness and rotation
    float spiralAngle = coords.angle + spiralTwist;
    
    // Create spiral arms
    float spiralPattern = sin(spiralAngle * 8.0) * 0.5 + 0.5;
    
    // Add spiral depth variation
    float spiralDepth = sin(coords.depth * 1.5 + time) * 0.3 + 0.7;
    
    return spiralPattern * spiralDepth;
}

float calculateTunnelWalls(TunnelCoords coords, float time) {
    // Create tunnel wall texture using noise and patterns
    float wallNoise = smoothNoise(float2(coords.angle * 4.0, coords.depth * 0.5) + time * 0.5);
    
    // Add wall detail patterns
    float wallDetail = sin(coords.angle * 12.0 + coords.depth * 2.0) * 0.3 + 0.7;
    
    // Combine wall elements
    float wallPattern = (wallNoise + wallDetail) * 0.5;
    
    return wallPattern;
}

float calculateVortexDistortion(TunnelCoords coords, float time) {
    // Create vortex distortion effect
    float vortexStrength = sin(time * 1.5) * 0.5 + 0.5;
    float vortexTwist = coords.radius * coords.radius * vortexStrength;
    
    // Apply vortex rotation
    float distortedAngle = coords.angle + vortexTwist + time * 2.0;
    float vortexPattern = sin(distortedAngle * 6.0 + coords.depth) * 0.4 + 0.6;
    
    return vortexPattern;
}

// PATTERN 12: 3D Tunnel Vortex Effect
[[ stitchable ]] half4 dotGridTunnel(float2 position, half4 color, float2 size, float time, float density, float dotSize, float colorHue, float colorEnabled, float bloomIntensity, float bloomRadius, float brightness) {
    float gridSize = mix(14.0, 32.0, density);
    float cellSize = min(size.x, size.y) / gridSize;
    
    float2 gridCoord = floor(position / cellSize);
    float2 cellCenter = (gridCoord + 0.5) * cellSize;
    
    // Calculate tunnel coordinates
    TunnelCoords tunnelCoords = calculateTunnelCoords(cellCenter, size, time);
    
    // Calculate tunnel effects
    float ringPattern = calculateTunnelRings(tunnelCoords, time);
    float spiralPattern = calculateTunnelSpiral(tunnelCoords, time);
    float wallPattern = calculateTunnelWalls(tunnelCoords, time);
    float vortexPattern = calculateVortexDistortion(tunnelCoords, time);
    
    // Combine tunnel patterns with much higher weighting for rings
    float tunnelIntensity = ringPattern * 0.7 + spiralPattern * 0.2 + wallPattern * 0.1;
    
    // Don't apply perspective to intensity - keep it bright
    // tunnelIntensity *= tunnelCoords.perspective;
    
    // Create much more dramatic depth-based fade
    float depthFade = 1.0 - smoothstep(0.0, 1.5, tunnelCoords.radius);
    tunnelIntensity *= depthFade;
    
    // Much more dramatic dot size variation with minimum size
    float baseTunnelSize = tunnelCoords.perspective * 4.0; // Even more dramatic scaling
    float tunnelDotSize = dotSize * max(0.3, baseTunnelSize + tunnelIntensity * 1.5); // Ensure minimum size
    
    // Add tunnel motion pulsing
    float motionPulse = sin(tunnelCoords.depth * 3.0 - time * 5.0) * 0.2 + 0.8;
    tunnelDotSize *= motionPulse;
    
    // Add vortex size variation
    float vortexSize = sin(tunnelCoords.angle * 4.0 + time * 3.0) * 0.2 + 0.8;
    tunnelDotSize *= vortexSize;
    
    // Distance from position to cell center
    float distanceToCenter = length(position - cellCenter);
    float dotRadius = cellSize * tunnelDotSize * 0.35;
    
    // Create perfect circle with tunnel-influenced softness
    float tunnelSoftness = 1.0 + (1.0 - tunnelCoords.perspective) * 2.0; // Further = softer
    float dot = 1.0 - smoothstep(dotRadius - tunnelSoftness, dotRadius + tunnelSoftness, distanceToCenter);
    
    // Enhanced brightness with dramatic tunnel contrast
    float tunnelBrightness = 0.3 + tunnelIntensity * 1.8;
    
    // Reduce fog effect to keep things visible with better contrast
    float fog = 1.0 - smoothstep(2.0, 8.0, tunnelCoords.depth * 0.1);
    tunnelBrightness *= (0.2 + fog * 0.8); // Enhanced minimum brightness
    
    // Enhanced tunnel center glow for better depth perception
    float centerGlow = 1.0 - smoothstep(0.0, 0.6, tunnelCoords.radius);
    tunnelBrightness += centerGlow * 1.2;
    
    // Enhanced speed lines effect for better motion
    float speedLines = sin(tunnelCoords.angle * 16.0 + time * 8.0) * 0.2 + 0.9;
    tunnelBrightness *= speedLines;
    
    // Enhanced tunnel lighting effects for better visibility
    float tunnelLighting = sin(tunnelCoords.depth * 2.0 + time * 1.5) * 0.4 + 0.8;
    tunnelBrightness *= tunnelLighting;
    
    // Apply strong contrast for tunnel depth clarity
    tunnelBrightness = pow(tunnelBrightness, 1.3); // Medium-strong gamma for 3D tunnel effect
    tunnelBrightness = clamp(tunnelBrightness, 0.0, 2.0);
    
    // Apply brightness multiplier
    tunnelBrightness *= brightness;
    
    // Create colors based on toggle
    float3 finalColor;
    if (colorEnabled > 0.5) {
        // Tunnel depth-based color progression
        float depthHue = colorHue + tunnelCoords.depth * 0.1;
        
        // Add rainbow tunnel effect
        float rainbowShift = sin(tunnelCoords.angle * 2.0 + time) * 0.3;
        depthHue += rainbowShift;
        
        // Vortex color swirling
        float vortexHue = sin(tunnelCoords.angle * 3.0 + tunnelCoords.depth + time * 2.0) * 0.2;
        depthHue += vortexHue;
        
        // Apply perspective to color intensity
        float colorIntensity = tunnelBrightness * (0.5 + tunnelCoords.perspective * 0.5);
        
        finalColor = createGradientColor(depthHue, colorIntensity, tunnelIntensity);
        
        // Add tunnel energy effect
        float energyPulse = sin(tunnelCoords.depth * 5.0 + time * 4.0) * 0.1 + 0.9;
        finalColor *= energyPulse;
        
        // Add chromatic aberration effect for realism
        float aberration = (1.0 - tunnelCoords.perspective) * 0.1;
        finalColor.r *= (1.0 + aberration);
        finalColor.b *= (1.0 - aberration);
    } else {
        finalColor = float3(tunnelBrightness);
    }
    
    // Apply bloom effect
    finalColor = applyBloom(finalColor, position, size, bloomIntensity, bloomRadius);
    
    return half4(half3(finalColor * dot), color.a);
}

// Wave interference physics structures
struct WaveSource {
    float2 position;
    float amplitude;
    float frequency;
    float phase;
    float wavelength;
};

WaveSource createWaveSource(float2 screenSize, float time, int index) {
    WaveSource source;
    
    // Different positions for wave sources
    float offset = float(index) * 2.094; // Roughly 2π/3 for good separation
    float radius = 0.25 + sin(time * 0.3 + offset) * 0.15; // Slowly moving sources
    
    // Orbital motion for dynamic interference patterns
    float angle = time * 0.4 + offset;
    float2 center = screenSize * 0.5;
    source.position = center + float2(
        cos(angle) * radius * min(screenSize.x, screenSize.y),
        sin(angle * 1.2) * radius * min(screenSize.x, screenSize.y) * 0.8
    );
    
    // Wave properties
    source.amplitude = 0.8 + sin(time * 0.8 + offset * 1.5) * 0.3;
    source.frequency = 1.2 + sin(time * 0.5 + offset) * 0.4; // Varying frequency
    source.phase = offset + time * 0.6; // Phase offset for each source
    source.wavelength = 60.0 + sin(time * 0.3 + offset) * 20.0; // Dynamic wavelength
    
    return source;
}

float calculateWaveAtPosition(float2 position, WaveSource source, float time) {
    // Calculate distance from wave source
    float distance = length(position - source.position);
    
    // Wave number (2π/wavelength)
    float waveNumber = 2.0 * 3.14159 / source.wavelength;
    
    // Classic wave equation: A * sin(kx - ωt + φ)
    float waveValue = source.amplitude * sin(waveNumber * distance - source.frequency * time + source.phase);
    
    // Add amplitude decay with distance (like real water ripples)
    float decay = 1.0 / (1.0 + distance * 0.002);
    waveValue *= decay;
    
    return waveValue;
}

float calculateInterferencePattern(float2 position, WaveSource sources[4], float time) {
    // Calculate wave contribution from each source
    float wave1 = calculateWaveAtPosition(position, sources[0], time);
    float wave2 = calculateWaveAtPosition(position, sources[1], time);
    float wave3 = calculateWaveAtPosition(position, sources[2], time);
    float wave4 = calculateWaveAtPosition(position, sources[3], time);
    
    // Superposition principle - add all waves together
    float totalWave = wave1 + wave2 + wave3 + wave4;
    
    return totalWave;
}

float calculateWaveIntensity(float waveAmplitude) {
    // Convert wave amplitude to visible intensity
    // Square the amplitude for realistic intensity (like real waves)
    float intensity = waveAmplitude * waveAmplitude;
    
    // Normalize and enhance contrast
    intensity = intensity * 0.25 + 0.5; // Scale to visible range
    
    return intensity;
}

float calculateInterferenceNodes(float2 position, WaveSource sources[4]) {
    // Calculate interference node patterns (standing wave patterns)
    float node1 = length(position - sources[0].position) - length(position - sources[1].position);
    float node2 = length(position - sources[2].position) - length(position - sources[3].position);
    
    // Create node line patterns
    float nodePattern1 = sin(node1 * 0.02) * 0.3 + 0.7;
    float nodePattern2 = sin(node2 * 0.02) * 0.3 + 0.7;
    
    return nodePattern1 * nodePattern2;
}

// PATTERN 13: Wave Interference Physics
[[ stitchable ]] half4 dotGridInterference(float2 position, half4 color, float2 size, float time, float density, float dotSize, float colorHue, float colorEnabled, float bloomIntensity, float bloomRadius, float brightness) {
    float gridSize = mix(16.0, 38.0, density);
    float cellSize = min(size.x, size.y) / gridSize;
    
    float2 gridCoord = floor(position / cellSize);
    float2 cellCenter = (gridCoord + 0.5) * cellSize;
    
    // Create multiple wave sources
    WaveSource sources[4];
    sources[0] = createWaveSource(size, time, 0);
    sources[1] = createWaveSource(size, time, 1);
    sources[2] = createWaveSource(size, time, 2);
    sources[3] = createWaveSource(size, time, 3);
    
    // Calculate wave interference at this position
    float interferenceWave = calculateInterferencePattern(cellCenter, sources, time);
    
    // Convert wave amplitude to intensity
    float waveIntensity = calculateWaveIntensity(interferenceWave);
    
    // Calculate interference node patterns
    float nodePattern = calculateInterferenceNodes(cellCenter, sources);
    
    // Combine wave intensity with node patterns
    float totalIntensity = waveIntensity * nodePattern;
    
    // Create constructive/destructive interference visualization
    float constructiveInterference = max(0.0, interferenceWave);
    float destructiveInterference = max(0.0, -interferenceWave);
    
    // Dynamic dot size based on wave interference
    float interferenceDotSize = dotSize * (0.5 + totalIntensity * 1.0);
    
    // Add wave motion effects
    float waveMotion = sin(interferenceWave * 5.0 + time * 3.0) * 0.2 + 0.8;
    interferenceDotSize *= waveMotion;
    
    // Add constructive interference size boost
    float constructiveBoost = constructiveInterference * 0.4 + 1.0;
    interferenceDotSize *= constructiveBoost;
    
    // Distance from position to cell center
    float distanceToCenter = length(position - cellCenter);
    float dotRadius = cellSize * interferenceDotSize * 0.35;
    
    // Create perfect circle with wave-influenced softness
    float waveSoftness = 1.0 + abs(interferenceWave) * 0.5; // More intense waves = softer edges
    float dot = 1.0 - smoothstep(dotRadius - waveSoftness, dotRadius + waveSoftness, distanceToCenter);
    
    // Enhanced brightness with dramatic wave interference contrast
    float interferenceBrightness = 0.15 + totalIntensity * 1.3;
    
    // Enhanced constructive interference brightness for better visibility
    interferenceBrightness += constructiveInterference * 0.7;
    
    // Enhanced destructive interference reduction for better contrast
    interferenceBrightness -= destructiveInterference * 0.5;
    
    // Enhanced wave source proximity glow
    float sourceGlow = 0.0;
    for (int i = 0; i < 4; i++) {
        float distToSource = length(position - sources[i].position);
        sourceGlow += sources[i].amplitude / (1.0 + distToSource / 100.0);
    }
    interferenceBrightness += sourceGlow * 0.3;
    
    // Enhanced wave propagation shimmer for better definition
    float shimmer = sin(totalIntensity * 8.0 + time * 4.0) * 0.4 + 0.8;
    interferenceBrightness *= shimmer;
    
    // Apply strong contrast for wave interference clarity
    interferenceBrightness = pow(interferenceBrightness, 1.6); // Strong gamma for physics clarity
    interferenceBrightness = clamp(interferenceBrightness, 0.0, 1.9);
    
    // Apply brightness multiplier
    interferenceBrightness *= brightness;
    
    // Create colors based on toggle
    float3 finalColor;
    if (colorEnabled > 0.5) {
        // Color based on wave phase and interference type
        float phaseHue = colorHue;
        
        // Constructive interference - warmer colors
        if (constructiveInterference > destructiveInterference) {
            phaseHue += constructiveInterference * 0.3; // Shift toward warm colors
        } else {
            // Destructive interference - cooler colors
            phaseHue -= destructiveInterference * 0.3; // Shift toward cool colors
        }
        
        // Add wave frequency color modulation
        float frequencyShift = 0.0;
        for (int i = 0; i < 4; i++) {
            float distToSource = length(position - sources[i].position);
            float sourceInfluence = 1.0 / (1.0 + distToSource / 150.0);
            frequencyShift += sources[i].frequency * sourceInfluence * 0.1;
        }
        phaseHue += frequencyShift;
        
        finalColor = createGradientColor(phaseHue, interferenceBrightness, totalIntensity);
        
        // Add wave interference rainbow effect
        float rainbowEffect = sin(interferenceWave * 3.0 + time * 2.0) * 0.1 + 0.9;
        finalColor *= rainbowEffect;
        
        // Add chromatic dispersion effect (like light through water)
        float dispersion = abs(interferenceWave) * 0.05;
        finalColor.r *= (1.0 + dispersion);
        finalColor.g *= (1.0);
        finalColor.b *= (1.0 - dispersion);
    } else {
        finalColor = float3(interferenceBrightness);
    }
    
    // Apply bloom effect
    finalColor = applyBloom(finalColor, position, size, bloomIntensity, bloomRadius);
    
    return half4(half3(finalColor * dot), color.a);
}
