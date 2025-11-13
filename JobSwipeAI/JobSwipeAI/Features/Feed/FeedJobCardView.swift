import SwiftUI

struct FeedJobCardView: View {
    let job: JobPosting

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(job.title)
                        .font(.headline)
                    Text(job.companyName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Label(job.employmentType.displayName, systemImage: "briefcase")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.15))
                    .clipShape(Capsule())
            }

            HStack(spacing: 12) {
                Label(job.location, systemImage: "mappin.and.ellipse")
                if let salary = job.salaryDescription.nonEmpty {
                    Label(salary, systemImage: "dollarsign")
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            if let responsibilitiesPreview = job.responsibilities.first {
                Text(responsibilitiesPreview)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }

            HStack {
                ForEach(job.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Capsule())
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}

#Preview {
    FeedJobCardView(job: JobPosting(
        id: "demo",
        title: "Senior iOS Engineer",
        companyName: "JobSwipe AI",
        location: "Remote",
        isRemote: true,
        employmentType: .fullTime,
        salaryMin: 150000,
        salaryMax: 190000,
        currency: "USD",
        description: "Build the swipe-to-apply experience.",
        requirements: ["Swift", "SwiftUI"],
        responsibilities: ["Ship features", "Collaborate"],
        postedAt: .now,
        source: .mock
    ))
    .padding()
    .background(Color(.systemGroupedBackground))
}
