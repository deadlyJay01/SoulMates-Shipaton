//
//  DailyQuestionBank.swift
//  SoulMates
//

import Foundation

struct DailyQuestion: Identifiable, Equatable {
    let id: Int
    let question: String
    let options: [String]
}

struct DailyQuestionBank {
    static let questions: [DailyQuestion] = [
        DailyQuestion(id: 1, question: "What is our ideal Saturday night plan?", options: ["Movie night in bed with takeout", "Dressing up for a fancy dinner date", "Spontaneous late-night road trip", "Hosting friends or cooking together"]),
        DailyQuestion(id: 2, question: "What is my biggest tell when I'm stressed?", options: ["I get completely quiet and withdraw", "I start over-cleaning or pacing", "I talk non-stop to vent", "I get sleepy and take long naps"]),
        DailyQuestion(id: 3, question: "Which trip should we prioritize next?", options: ["A secluded cabin in the mountains", "A relaxed tropical beach resort", "A bustling international city", "An adventure road trip off the grid"]),
        DailyQuestion(id: 4, question: "What was your very first impression of me?", options: ["Instantly charming and warm", "Mysterious and hard to read", "Hilarious and full of energy", "Polite, quiet, and sweet"]),
        DailyQuestion(id: 5, question: "Which love language do you need most this week?", options: ["Physical touch (hugs, holding hands)", "Words of affirmation and check-ins", "Quality time without our phones", "Acts of service (taking care of chores)"]),
        DailyQuestion(id: 6, question: "If we could adopt any pet tomorrow, what would it be?", options: ["A golden retriever puppy", "A calm indoor rescue cat", "Two playful kittens", "No pets, we love traveling freely"]),
        DailyQuestion(id: 7, question: "What is the best dish I cook or meal we share?", options: ["Late-night comfort street food", "Homemade pasta or skillet dinners", "Our morning breakfast coffee routine", "Our favorite dessert spot order"]),
        DailyQuestion(id: 8, question: "What song instantly reminds you of us?", options: ["Our slow dance romantic song", "That funny hype song on road trips", "The song that played on our first date", "A cozy acoustic indie track"]),
        DailyQuestion(id: 9, question: "If we had an unexpected $5,000, what should we do?", options: ["Book an unforgettable couple vacation", "Put it straight into our future savings", "Upgrade our living room setup", "Splurge on matching luxury treats"]),
        DailyQuestion(id: 10, question: "How do you prefer we resolve disagreements?", options: ["Talk it through calmly right away", "Take 30 minutes to cool off first", "A long warm hug before saying words", "Write our thoughts down in notes"]),
        DailyQuestion(id: 11, question: "What is my cutest quirk?", options: ["The faces I make when thinking", "How passionate I get talking about hobbies", "The morning sleepy voice", "How I laugh when something is truly funny"]),
        DailyQuestion(id: 12, question: "What is our relationship superpower?", options: ["Unbeatable communication and honesty", "We always laugh through awkward moments", "Unconditional loyalty and support", "We give each other freedom to grow"]),
        DailyQuestion(id: 13, question: "Which movie genre describes our dynamic best?", options: ["Heartwarming rom-com", "Chaotic action-comedy duo", "Sweet coming-of-age drama", "Cozy fantasy adventure"]),
        DailyQuestion(id: 14, question: "What is one dream habit we should build together?", options: ["Working out or walking every evening", "Cooking new recipes together on Sundays", "Reading together without screens before bed", "Planning a weekly surprise mini date"]),
        DailyQuestion(id: 15, question: "When do you feel most loved by me?", options: ["When I notice small details about your day", "During quiet forehead kisses and cuddles", "When I cheer for your accomplishments", "When I bring you your favorite snack unasked"]),
        DailyQuestion(id: 16, question: "If we swapped bodies for one day, what's my biggest challenge?", options: ["Handling your daily work schedule", "Dealing with your sleep cycle", "Picking outfits you would wear", "Remembering where all your things are"]),
        DailyQuestion(id: 17, question: "What is our go-to comfort order on food apps?", options: ["Cheesy Pizza & garlic bread", "Spicy Asian Noodles / Ramen", "Burgers, fries, and shakes", "Warm Biryani or comfort curries"]),
        DailyQuestion(id: 18, question: "What do you miss most about each other when apart?", options: ["Falling asleep and waking up next to you", "Laughing at random TikToks and reels", "Your voice and spontaneous hugs", "Having someone to debrief my day with"]),
        DailyQuestion(id: 19, question: "What was our single most memorable date so far?", options: ["The very first time we hung out", "That rainy day date where plans failed", "Our anniversary dinner celebration", "That completely unplanned late-night walk"]),
        DailyQuestion(id: 20, question: "In 10 years, where do you picture us living?", options: ["A cozy suburban house with a big garden", "A sleek high-rise condo with city views", "A peaceful countryside cottage", "Traveling the world living in different cities"])
    ]

    // Offsets the calendar by 5 hours so the new question activates at 5:00 AM
    private static func adjusted5AMDate(_ date: Date = Date()) -> Date {
        // Subtract 5 hours (5 * 3600 seconds)
        // e.g. 4:59 AM on Sept 22 belongs to Sept 21. 5:00 AM on Sept 22 shifts to Sept 22.
        date.addingTimeInterval(-5 * 3600)
    }

    // Pick the question for today (resets at 5:00 AM)
    static func questionForDate(_ date: Date = Date()) -> DailyQuestion {
        let adjusted = adjusted5AMDate(date)
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: adjusted) ?? 1
        let index = (dayOfYear - 1) % questions.count
        return questions[index]
    }

    // Date key format (e.g., "2026-09-21") reset at 5:00 AM
    static func dateKey(for date: Date = Date()) -> String {
        let adjusted = adjusted5AMDate(date)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: adjusted)
    }
}
