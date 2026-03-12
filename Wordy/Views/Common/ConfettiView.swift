//1
//  ConfettiView.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 30.01.2026.
//

import SwiftUI


struct ConfettiView: View {
    @State private var particles: [Particle] = []
    
    let colors: [Color] = [
        Color(hex: "#4ECDC4"),
        Color(hex: "#F38BA8"),
        Color(hex: "#95E1D3"),
        Color(hex: "#FFD700"),
        Color(hex: "#A8D8EA"),
        Color(hex: "#F38181")
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiPiece(
                        particle: particle,
                        screenWidth: geometry.size.width,
                        screenHeight: geometry.size.height
                    )
                }
                
                // Хлопушка по центру зверху
                Text("🎉")
                    .font(.system(size: 60))
                    .position(x: geometry.size.width / 2, y: 100)
                    .rotationEffect(.degrees(-45))
            }
            .onAppear {
                generateParticles()
                // Видаляємо частинки через 3 секунди
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    particles.removeAll()
                }
            }
        }
        .ignoresSafeArea()
    }
    
    private func generateParticles() {
        particles = (0..<60).map { i in
            Particle(
                x: 0.5, // Починаємо з центру (хлопушка)
                y: 0.15, // Трохи зверху
                color: colors.randomElement()!,
                size: CGFloat.random(in: 6...14),
                rotation: Double.random(in: 0...360),
                speed: Double.random(in: 1.5...3),
                direction: Double.random(in: -45...225) // Розлітаються вниз-вбік
            )
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat // 0...1 (відсоток ширини)
    var y: CGFloat // 0...1 (відсоток висоти)
    var color: Color
    var size: CGFloat
    var rotation: Double
    var speed: Double
    var direction: Double // Кут розльоту в градусах
}

struct ConfettiPiece: View {
    let particle: Particle
    let screenWidth: CGFloat
    let screenHeight: CGFloat
    
    @State private var position: CGPoint = .zero
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1
    @State private var scale: CGFloat = 0
    
    var body: some View {
        Circle()
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size)
            .position(position)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .scaleEffect(scale)
            .onAppear {
                // Початкова позиція (центр зверху)
                position = CGPoint(
                    x: particle.x * screenWidth,
                    y: particle.y * screenHeight
                )
                rotation = particle.rotation
                
                // Анімація розльоту
                withAnimation(.easeOut(duration: particle.speed)) {
                    let radians = particle.direction * .pi / 180
                    let distance = CGFloat.random(in: 100...300)
                    position.x += cos(radians) * distance
                    position.y += sin(radians) * distance + 200 // Падають вниз
                    rotation += Double.random(in: 360...720)
                    scale = 1.0
                }
                
                // Затухання
                withAnimation(.easeIn(duration: 0.4).delay(particle.speed - 0.4)) {
                    opacity = 0
                }
            }
    }
}
