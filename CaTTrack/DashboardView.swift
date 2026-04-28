//
//  DashboardView.swift
//  CaTTrack
//

import SwiftUI

struct DashboardView: View {
    @State private var isGoalsExpanded: Bool = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Cat Profile Card
                    VStack(spacing: 12) {
                        HStack(spacing: 16) {
                            Image(systemName: "cat.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundStyle(.orange)
                                .padding(12)
                                .background(Color.orange.opacity(0.15))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Whiskers")
                                    .font(.title2)
                                    .bold()
                                Text("Siamese • 3 years old")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }

                        Divider()

                        HStack(spacing: 24) {
                            statBadge(icon: "scalemass.fill", label: "Weight", value: "4.5 kg")
                            statBadge(icon: "chart.bar.fill", label: "BMI", value: "--")
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)

                    // Daily Goals Section (Minimizable)
                    VStack(spacing: 0) {
                        Button(action: {
                            withAnimation(.spring()) {
                                isGoalsExpanded.toggle()
                            }
                        }) {
                            HStack {
                                Image(systemName: "target")
                                    .foregroundStyle(.blue)
                                Text("Daily Goals & Stats")
                                    .font(.headline)
                                Spacer()
                                Image(systemName: isGoalsExpanded ? "chevron.up" : "chevron.down")
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                        }
                        .buttonStyle(.plain)

                        if isGoalsExpanded {
                            VStack(spacing: 16) {
                                goalCard(icon: "flame.fill", title: "Calories", current: "0", goal: "250", color: .red)
                                goalCard(icon: "drop.fill", title: "Water", current: "0", goal: "200 ml", color: .cyan)
                                goalCard(icon: "toilet.fill", title: "Restroom", current: "0", goal: "3 visits", color: .green)
                            }
                            .padding()
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)

                    // Quick Actions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Quick Actions")
                            .font(.headline)
                            .padding(.horizontal)

                        HStack(spacing: 12) {
                            quickActionButton(icon: "plus.circle.fill", label: "Log Meal", color: .orange)
                            quickActionButton(icon: "drop.circle.fill", label: "Log Water", color: .cyan)
                            quickActionButton(icon: "checkmark.circle.fill", label: "Check-in", color: .green)
                        }
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func statBadge(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func goalCard(icon: String, title: String, current: String, goal: String, color: Color) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .foregroundStyle(color)
                .padding(10)
                .background(color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("\(current) / \(goal)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Placeholder progress ring
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 4)
                    .frame(width: 40, height: 40)
                Circle()
                    .trim(from: 0, to: 0.0)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                Text("0%")
                    .font(.caption2)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private func quickActionButton(icon: String, label: String, color: Color) -> some View {
        Button(action: {}) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundStyle(color)
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    DashboardView()
}

