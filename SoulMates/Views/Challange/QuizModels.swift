//
//  QuizModels.swift
//  SoulMates
//

import SwiftUI

// MARK: - Models

struct QuizGame: Identifiable {
    let id: String
    let title: String
    let description: String
    let emoji: String
    let color: Color
    let questions: [QuizQuestion]
}

struct QuizCategory: Identifiable {
    let id: String
    let title: String
    let games: [QuizGame]
}

struct QuizQuestion: Identifiable {
    let id: String
    let question: String
    let options: [String]
}

// Added Equatable here
struct SavedQuizAnswer: Codable, Equatable {
    let question: String
    let answer: String
}

// MARK: - Mock Dataset

let quizCategories: [QuizCategory] = [

    // Category 1: Know Each Other
    QuizCategory(
        id: "know_each_other",
        title: "Know Each Other",
        games: [
            QuizGame(
                id: "how_well_know_me",
                title: "How Well Do You Know Me?",
                description: "See how well you remember the little things about your partner.",
                emoji: "🧠",
                color: .blue,
                questions: [
                    QuizQuestion(id: "k1", question: "What do you think I enjoy doing most on a lazy day?", options: ["Watching movies or shows", "Going outside somewhere", "Gaming all day", "Sleeping in"]),
                    QuizQuestion(id: "k2", question: "What surprise would make me happiest?", options: ["Romantic date", "Fun adventure", "Thoughtful gift", "Quiet night in"]),
                    QuizQuestion(id: "k3", question: "What would I pick for a perfect Sunday?", options: ["Stay home together", "Take a day trip", "Hang out with friends", "Try something new"]),
                    QuizQuestion(id: "k4", question: "When I have a rough day, what do I need most?", options: ["A long hug", "A little quiet space", "A listening ear", "A fun distraction"]),
                    QuizQuestion(id: "k5", question: "Which small thing matters most to me?", options: ["Sweet random texts", "Remembering details", "Quality uninterrupted time", "Surprise snacks"])
                ]
            ),
            QuizGame(
                id: "my_favorites",
                title: "My Favorites",
                description: "Guess your partner's ultimate favorite things.",
                emoji: "❤️",
                color: .red,
                questions: [
                    QuizQuestion(id: "f1", question: "What food would I crave first?", options: ["Pizza", "Burgers & fries", "Home cooked comfort meal", "Street food"]),
                    QuizQuestion(id: "f2", question: "What genre of entertainment do I reach for?", options: ["Comedy", "Romance", "Action & Thriller", "Sci-Fi / Fantasy"]),
                    QuizQuestion(id: "f3", question: "What getaway destination sounds like me?", options: ["Sunny beach", "Serene mountains", "Vibrant metro city", "Cozy forest cabin"]),
                    QuizQuestion(id: "f4", question: "Which evening plan sounds most appealing?", options: ["Movie marathon", "Dressed-up dinner date", "Gaming together", "Late-night drive"]),
                    QuizQuestion(id: "f5", question: "What kind of gift do I appreciate most?", options: ["Something practical", "Handmade & sentimental", "A fun surprise", "A shared experience"])
                ]
            ),
            QuizGame(
                id: "guess_my_choice",
                title: "Guess My Choice",
                description: "Predict what your partner would choose in different scenarios.",
                emoji: "🤔",
                color: .purple,
                questions: [
                    QuizQuestion(id: "c1", question: "If we had a free day tomorrow, what would I pick?", options: ["Road trip", "Stay in bed", "Shopping spree", "Try a new café"]),
                    QuizQuestion(id: "c2", question: "If I could master any skill instantly, what would it be?", options: ["Cooking gourmet meals", "Playing an instrument", "Speaking 5 languages", "Photography"]),
                    QuizQuestion(id: "c3", question: "What couple activity would I choose right now?", options: ["Binge-watching a series", "Hiking outdoors", "Board game night", "Cooking together"]),
                    QuizQuestion(id: "c4", question: "What would my dream impromptu date look like?", options: ["Rooftop dinner", "Midnight drive", "Sunset picnic", "Theme park"]),
                    QuizQuestion(id: "c5", question: "What is my go-to rainy day vibe?", options: ["Blanket & hot coffee", "Driving in the rain", "Taking a nap", "Ordering comfort snacks"])
                ]
            ),
            QuizGame(
                id: "memory_lane",
                title: "Memory Lane",
                description: "Test your memory of special moments shared together.",
                emoji: "📸",
                color: .orange,
                questions: [
                    QuizQuestion(id: "m1", question: "Which memory would I replay again?", options: ["First time meeting", "Our hardest laugh", "Our first road trip", "A random quiet moment"]),
                    QuizQuestion(id: "m2", question: "Which moment felt most special to me early on?", options: ["First deep talk", "First photo together", "First trip together", "First celebration"]),
                    QuizQuestion(id: "m3", question: "What moments stick in my head most?", options: ["Inside jokes", "Late-night conversations", "Daily small routines", "Surprise moments"]),
                    QuizQuestion(id: "m4", question: "Which photo of us would I frame?", options: ["Silly candid picture", "Dressed-up photo", "Scenic trip picture", "Cozy home selfie"]),
                    QuizQuestion(id: "m5", question: "What belongs most in our relationship scrapbook?", options: ["Candid polaroids", "Handwritten notes", "Saved tickets & stubs", "Funny quotes"])
                ]
            ),
            QuizGame(
                id: "complete_my_sentence",
                title: "Complete My Sentence",
                description: "Try to predict how your partner would finish each thought.",
                emoji: "💬",
                color: .green,
                questions: [
                    QuizQuestion(id: "s1", question: "When I am happiest with you, I usually want to...", options: ["Talk for hours", "Explore new places", "Just cuddle quietly", "Eat great food"]),
                    QuizQuestion(id: "s2", question: "The perfect date night always involves...", options: ["No phone distractions", "Good music & vibes", "Lots of laughs", "A beautiful view"]),
                    QuizQuestion(id: "s3", question: "When I miss you, my instinct is to...", options: ["Call right away", "Send funny memes", "Look at our photos", "Plan our next hangout"]),
                    QuizQuestion(id: "s4", question: "Something that instantly makes me smile is...", options: ["Your laugh", "A sweet surprise", "A silly joke", "A warm embrace"]),
                    QuizQuestion(id: "s5", question: "When we grow old together, I hope we still...", options: ["Travel everywhere", "Bicker over silly things", "Hold hands in public", "Laugh at each other"])
                ]
            ),
            QuizGame(
                id: "do_you_remember",
                title: "Do You Remember?",
                description: "Answer fun questions about little details from your relationship.",
                emoji: "🫶",
                color: .pink,
                questions: [
                    QuizQuestion(id: "r1", question: "What detail from our start do I remember most?", options: ["How nervous we were", "The music playing", "Our endless texts", "Where we met"]),
                    QuizQuestion(id: "r2", question: "What memory would I never want to forget?", options: ["A deep emotional talk", "A chaotic adventure", "A milestone date", "A silly mistake"]),
                    QuizQuestion(id: "r3", question: "Which story do I share with others most?", options: ["How we met", "A funny disaster", "Our first trip", "A sweet surprise"]),
                    QuizQuestion(id: "r4", question: "What daily routine between us is most grounding?", options: ["Morning messages", "Sharing dinner updates", "Late night calls", "Sending funny reels"]),
                    QuizQuestion(id: "r5", question: "What memory brings an instant grin?", options: ["A rainy day hangout", "A failed surprise", "Dancing in the room", "Our first drive"])
                ]
            )
        ]
    ),

    // Category 2: Love & Romance
    QuizCategory(
        id: "love_romance",
        title: "Love & Romance",
        games: [
            QuizGame(
                id: "love_language",
                title: "Love Language",
                description: "Explore how you both feel most appreciated and adored.",
                emoji: "💌",
                color: .pink,
                questions: [
                    QuizQuestion(id: "l1", question: "What makes you feel most adored?", options: ["Words of affirmation", "Dedicated quality time", "Thoughtful little gifts", "Physical affection & hugs"]),
                    QuizQuestion(id: "l2", question: "What gesture melts your heart?", options: ["Handwritten card", "Surprise date plan", "Bringing favorite snacks", "Holding hands unexpectedly"]),
                    QuizQuestion(id: "l3", question: "How do you naturally express care?", options: ["Compliments", "Helping out with tasks", "Planning special outings", "Hugging and cuddling"]),
                    QuizQuestion(id: "l4", question: "What turns a routine day romantic?", options: ["Sweet check-in text", "Cooking dinner together", "Dancing to a slow track", "An evening walk"]),
                    QuizQuestion(id: "l5", question: "After a tiring day, what do you need most?", options: ["A quiet listener", "A long warm hug", "Silent relaxing together", "A comfort meal"])
                ]
            ),
            QuizGame(
                id: "romantic_choices",
                title: "Romantic Choices",
                description: "Choose the romantic experiences you would cherish most.",
                emoji: "🌹",
                color: .red,
                questions: [
                    QuizQuestion(id: "rc1", question: "Pick your ideal dreamy evening ambiance.", options: ["Candlelit private dinner", "Beach sunset walk", "Stargazing on a roof", "Cozy blankets & movie"]),
                    QuizQuestion(id: "rc2", question: "What makes a date truly special?", options: ["An unexpected surprise", "A stunning view", "Delicious food", "Deep conversation"]),
                    QuizQuestion(id: "rc3", question: "Which romantic date sounds best?", options: ["Baking treats together", "Slow dancing at home", "Midnight long drive", "Park picnic"]),
                    QuizQuestion(id: "rc4", question: "What surprise gesture is your favorite?", options: ["Favorite flowers", "Random craving delivered", "Weekend trip reveal", "A tailored playlist"]),
                    QuizQuestion(id: "rc5", question: "What romantic tradition should we keep?", options: ["Monthly date nights", "Annual getaway trip", "Leaving cute sticky notes", "Sunday coffee ritual"])
                ]
            ),
            QuizGame(
                id: "first_date",
                title: "First Date",
                description: "Revisit early spark vibes and first impression feels.",
                emoji: "🥰",
                color: .orange,
                questions: [
                    QuizQuestion(id: "fd1", question: "What was the best kind of first date?", options: ["Coffee & talking", "Dinner date", "Arcade / activities", "Scenic walk"]),
                    QuizQuestion(id: "fd2", question: "What broke the ice quickest?", options: ["Laughing at something silly", "Childhood stories", "Favorite music tastes", "Food opinions"]),
                    QuizQuestion(id: "fd3", question: "Which moment gave the biggest butterflies?", options: ["First eye contact", "First shared big laugh", "Subtle hand touch", "The goodbye hug"]),
                    QuizQuestion(id: "fd4", question: "What lingered in mind right after?", options: ["The conversation", "How they dressed", "The atmosphere", "How effortless it felt"]),
                    QuizQuestion(id: "fd5", question: "How would you describe our vibe from day one?", options: ["Natural and easy", "Playful banter", "Instantly electric", "Calm and comfortable"])
                ]
            ),
            QuizGame(
                id: "sweet_talk",
                title: "Sweet Talk",
                description: "Answer cute and heart-fluttering questions together.",
                emoji: "🍫",
                color: .purple,
                questions: [
                    QuizQuestion(id: "st1", question: "What compliment hits deepest?", options: ["About character and mind", "About smile and looks", "About how safe I make you feel", "About quirky habits"]),
                    QuizQuestion(id: "st2", question: "What text brightens your whole day?", options: ["Cute morning text", "Late night paragraph", "Mid-day 'miss you'", "Inside joke meme"]),
                    QuizQuestion(id: "st3", question: "What nickname sounds sweetest?", options: ["Babe / Baby", "Honey / Sweetheart", "My Love", "Personal cute nickname"]),
                    QuizQuestion(id: "st4", question: "What makes voice notes sweet?", options: ["Sleepy voices", "Daily random updates", "Whispered good nights", "Unfiltered laughs"]),
                    QuizQuestion(id: "st5", question: "What makes a relationship last forever?", options: ["Total honesty", "Consistent daily effort", "Deep emotional bond", "Nonstop laughter"])
                ]
            ),
            QuizGame(
                id: "couple_goals",
                title: "Couple Goals",
                description: "Compare your relationship philosophies and inspirations.",
                emoji: "💑",
                color: .blue,
                questions: [
                    QuizQuestion(id: "cg1", question: "What is our biggest shared dream?", options: ["Traveling the world", "Building a cozy home", "Building big careers together", "A peaceful, simple life"]),
                    QuizQuestion(id: "cg2", question: "What should couples never stop doing?", options: ["Going on dates", "Talking openly", "Growing individually", "Laughing at silly things"]),
                    QuizQuestion(id: "cg3", question: "What keeps us closest during busy times?", options: ["Morning coffee check-ins", "Random midday texts", "Leaving little surprises", "Unwinding before bed"]),
                    QuizQuestion(id: "cg4", question: "Which couple hobby should we pick up?", options: ["Fitness & gym duo", "Cooking masterclasses", "Creative photography", "Travel planning"]),
                    QuizQuestion(id: "cg5", question: "Our dynamic can be best described as:", options: ["Best friends & soulmates", "Partners in crime", "Safe haven and calm", "Passionate power couple"])
                ]
            ),
            QuizGame(
                id: "love_challenge",
                title: "Love Challenge",
                description: "Challenge your partner with fun scenarios and preferences.",
                emoji: "💖",
                color: .green,
                questions: [
                    QuizQuestion(id: "lc1", question: "Pick a date challenge for this week:", options: ["Cook dinner under $15", "Plan a surprise blind date", "Recreate an early date", "No phones for 4 hours"]),
                    QuizQuestion(id: "lc2", question: "If we had 24 hours in a dream city, first stop:", options: ["Cozy local café", "Famous landmark at night", "Art & street market", "Scenic river walk"]),
                    QuizQuestion(id: "lc3", question: "Which romantic ritual should we try?", options: ["Monthly love notes", "Nightly check-in question", "Sunday morning stroll", "Random surprise gifts"]),
                    QuizQuestion(id: "lc4", question: "Best way to defuse a small disagreement?", options: ["Talk it through right away", "Take 10 mins cool-off time", "Hug first, talk second", "Write thoughts down"]),
                    QuizQuestion(id: "lc5", question: "Pick our soundtrack style:", options: ["Acoustic & warm guitar", "Classic retro romance", "Chill indie tracks", "Smooth R&B rhythm"])
                ]
            )
        ]
    ),

    // Category 3: Fun & Random
    QuizCategory(
        id: "fun_random",
        title: "Fun & Random",
        games: [
            QuizGame(
                id: "this_or_that",
                title: "This or That",
                description: "Pick between two choices and see how closely you align.",
                emoji: "⚡",
                color: .yellow,
                questions: [
                    QuizQuestion(id: "tt1", question: "Vacation vibe: Beach resort or mountain cabin?", options: ["Sunny beach resort", "Misty mountain cabin", "Vibrant city hotel", "Campervan adventure"]),
                    QuizQuestion(id: "tt2", question: "Night in: Movie marathon or gaming night?", options: ["Binge-watching shows", "Gaming / board games", "Listening to music", "Reading quietly"]),
                    QuizQuestion(id: "tt3", question: "Mornings: Early sunrise or sleep until noon?", options: ["Early sunrise riser", "Sleep in late", "Slow morning in bed", "Depends on the day"]),
                    QuizQuestion(id: "tt4", question: "Snack craving: Sweet dessert or savory bites?", options: ["Warm brownies / ice cream", "Crispy chips / fries", "Hot pizza slice", "Spicy street snacks"]),
                    QuizQuestion(id: "tt5", question: "Social plan: Big party or dinner with 2 close friends?", options: ["Big lively party", "Quiet dinner with friends", "Just the two of us", "Outdoor concert"])
                ]
            ),
            QuizGame(
                id: "would_you_rather",
                title: "Would You Rather?",
                description: "Make quirky, funny, and unexpected choices together.",
                emoji: "🎲",
                color: .purple,
                questions: [
                    QuizQuestion(id: "wr1", question: "Free international flights or unlimited free food?", options: ["Unlimited flights", "Unlimited free meals", "A mix of both", "Hardest choice ever"]),
                    QuizQuestion(id: "wr2", question: "Everything planned out or 100% winging it?", options: ["Every hour scheduled", "Completely spontaneous", "Hotels booked, rest open", "Partner decides"]),
                    QuizQuestion(id: "wr3", question: "No smartphone for 7 days or no favorite snack for 30?", options: ["Give up smartphone", "Give up favorite snack", "Neither sounds easy", "Phone goes first"]),
                    QuizQuestion(id: "wr4", question: "Teleport anywhere together or read each other's mind?", options: ["Instant teleportation", "Hear each other's thoughts", "Teleportation only", "Mind reading is scary"]),
                    QuizQuestion(id: "wr5", question: "Sing karaoke publicly or dance in the middle of a mall?", options: ["Karaoke performance", "Mall dance party", "Both together!", "Run and hide"])
                ]
            ),
            QuizGame(
                id: "who_more_likely",
                title: "Who Is More Likely?",
                description: "Find out who is most guilty of silly everyday habits.",
                emoji: "😂",
                color: .orange,
                questions: [
                    QuizQuestion(id: "wm1", question: "Who suggests a midnight road trip first?", options: ["Definitely me", "Definitely my partner", "Both equally", "Neither, we love sleep"]),
                    QuizQuestion(id: "wm2", question: "Who laughs out loud in a silent room?", options: ["Me without doubt", "My partner for sure", "Both together", "Whoever gets tickled"]),
                    QuizQuestion(id: "wm3", question: "Who orders way more food than we can finish?", options: ["Me, always hungry", "My partner, every time", "Both when starving", "Neither, good portions"]),
                    QuizQuestion(id: "wm4", question: "Who falls asleep 10 minutes into the movie?", options: ["Me, instantly", "My partner, guaranteed", "Both on cozy nights", "Neither, eyes glued"]),
                    QuizQuestion(id: "wm5", question: "Who takes longer to get ready for date night?", options: ["Definitely me", "Definitely my partner", "Both take forever", "We are super fast"])
                ]
            ),
            QuizGame(
                id: "guess_emoji",
                title: "Guess the Emoji",
                description: "Express your couple energy and dynamic through emojis.",
                emoji: "😎",
                color: .blue,
                questions: [
                    QuizQuestion(id: "ge1", question: "Which emoji fits our relationship personality?", options: ["❤️ Loving & Sweet", "😂 Goofy & Chaos", "🔥 Bold & Passionate", "🥰 Pure & Calm"]),
                    QuizQuestion(id: "ge2", question: "Which emoji is your partner when hangry?", options: ["😤 Grumpy cloud", "🥺 Sad puppy eyes", "🦖 Little monster", "🤐 Dead silent"]),
                    QuizQuestion(id: "ge3", question: "Which emoji describes our dream weekend?", options: ["🏖️ Beach waves", "🍕 Pizza coma", "🍿 Movie cinema", "🏕️ Mountain trek"]),
                    QuizQuestion(id: "ge4", question: "Which emoji matches when you see each other?", options: ["😍 Heart eyes", "🥳 Excited jump", "🫠 Melting into hug", "🤪 Silly face mode"]),
                    QuizQuestion(id: "ge5", question: "Which emoji represents our communication?", options: ["🗣️ Non-stop chatter", "📲 50 memes an hour", "🤫 Quiet telepathy", "💌 Thoughtful letters"])
                ]
            ),
            QuizGame(
                id: "rapid_fire",
                title: "Rapid Fire",
                description: "Answer questions in a snap—trust your instant gut feeling.",
                emoji: "🔥",
                color: .red,
                questions: [
                    QuizQuestion(id: "rf1", question: "Quick! Choose a spontaneous date destination:", options: ["Late-night ice cream", "City drive with music", "Arcade gaming", "Scenic lake view"]),
                    QuizQuestion(id: "rf2", question: "Quick! Pick a lazy morning brew:", options: ["Fresh hot coffee", "Warm spicy chai", "Chilled iced frappe", "Fruit smoothie"]),
                    QuizQuestion(id: "rf3", question: "Quick! Go-to cinema movie snack:", options: ["Buttery popcorn", "Cheesy nachos", "Sweet chocolates", "Soft drink"]),
                    QuizQuestion(id: "rf4", question: "Quick! One word for our relationship:", options: ["Electric", "Peaceful", "Hilarious", "Unshakeable"]),
                    QuizQuestion(id: "rf5", question: "Quick! Our superpower together is:", options: ["Mind reading", "Making each other laugh", "Calming each other down", "Unstoppable team"])
                ]
            ),
            QuizGame(
                id: "crazy_questions",
                title: "Crazy Questions",
                description: "Answer wild, hypothetical scenarios you never saw coming.",
                emoji: "🤪",
                color: .green,
                questions: [
                    QuizQuestion(id: "cq1", question: "If a zombie apocalypse hit, what are our roles?", options: ["Me fighter, you brain", "You fighter, me scout", "Both hiding with snacks", "Befriending zombies"]),
                    QuizQuestion(id: "cq2", question: "If a movie was made of us, what's the genre?", options: ["Romantic comedy", "Epic road adventure", "Chaotic documentary", "Sci-fi time travel"]),
                    QuizQuestion(id: "cq3", question: "If we swapped bodies for 24 hours, first move:", options: ["See what you think of me", "Raid your wardrobe", "Try your daily routine", "Prank our mutuals"]),
                    QuizQuestion(id: "cq4", question: "If we won a $10M lottery today, first purchase:", options: ["Round-the-world tickets", "Dream luxury villa", "Beach cottage sanctuary", "Cool vintage car"]),
                    QuizQuestion(id: "cq5", question: "Which universe would we thrive in together?", options: ["Marvel heroes", "Hogwarts magic", "Cozy animated world", "Star Wars galaxy"])
                ]
            )
        ]
    ),

    // Category 4: Future Together
    QuizCategory(
        id: "future_together",
        title: "Future Together",
        games: [
            QuizGame(
                id: "dream_life",
                title: "Dream Life",
                description: "Paint a picture of what your golden future looks like.",
                emoji: "✨",
                color: .purple,
                questions: [
                    QuizQuestion(id: "dl1", question: "What vibe should define our future home life?", options: ["Calm and stress-free", "Fast-paced & ambitious", "Cozy and family-filled", "Creative and free"]),
                    QuizQuestion(id: "dl2", question: "Where do we see our morning view in 10 years?", options: ["City skyline penthouse", "Ocean beach bungalow", "Peaceful countryside", "A new country each year"]),
                    QuizQuestion(id: "dl3", question: "What counts as our biggest milestone victory?", options: ["Lifelong friendship & love", "Creating something huge", "Seeing the whole world", "A warm, happy household"]),
                    QuizQuestion(id: "dl4", question: "How should our ideal weekday evening look?", options: ["Cooking while music plays", "Talking out on a patio", "Workout / evening stroll", "Cozy show binge"]),
                    QuizQuestion(id: "dl5", question: "What legacy of love do we leave behind?", options: ["Never stopped laughing", "Were an incredible team", "Loved unconditionally", "Lived with zero regrets"])
                ]
            ),
            QuizGame(
                id: "travel_together",
                title: "Travel Together",
                description: "Map out dream destinations and travel styles as a duo.",
                emoji: "✈️",
                color: .blue,
                questions: [
                    QuizQuestion(id: "tr1", question: "Top international destination on our list:", options: ["Santorini & Italian coast", "Cherry blossoms in Tokyo", "Swiss Alps peaks", "Bali / Maldives resort"]),
                    QuizQuestion(id: "tr2", question: "Our ideal travel pace together:", options: ["Explore every site in town", "Slow café hopping pace", "All-inclusive lounging", "Spontaneous road trip"]),
                    QuizQuestion(id: "tr3", question: "Best part of exploring new places together:", options: ["Tasting authentic dishes", "Discovering hidden spots", "Taking great couple shots", "Getting lost together"]),
                    QuizQuestion(id: "tr4", question: "How do we split travel duties?", options: ["One plans route, one picks food", "Research together", "One leads, one follows", "No plans, just go"]),
                    QuizQuestion(id: "tr5", question: "Most iconic travel memory to create:", options: ["Seeing Northern Lights", "Hot air balloon flight", "Coastal open-top drive", "Diving coral reefs"])
                ]
            ),
            QuizGame(
                id: "future_home",
                title: "Future Home",
                description: "Design and envision your future shared living sanctuary.",
                emoji: "🏠",
                color: .orange,
                questions: [
                    QuizQuestion(id: "fh1", question: "Centerpiece feature of our home:", options: ["Huge open chef kitchen", "Fireplace & reading nook", "Epic cinema setup", "Lush garden patio"]),
                    QuizQuestion(id: "fh2", question: "Interior design aesthetic:", options: ["Clean modern minimal", "Warm bohemian rustic", "Moody luxury accents", "Cozy Scandinavian Hygge"]),
                    QuizQuestion(id: "fh3", question: "What pet will run around our living room?", options: ["Playful golden retriever", "Cozy purring cat", "Multiple pets", "House plants only"]),
                    QuizQuestion(id: "fh4", question: "What feeling should visitors get at the door?", options: ["Warm, safe and inviting", "Super aesthetic and chic", "Lively and fun", "Quiet and serene"]),
                    QuizQuestion(id: "fh5", question: "Room where we spend most time together:", options: ["Living room couch", "Kitchen island cooking", "Bedroom sanctuary", "Balcony / garden"])
                ]
            ),
            QuizGame(
                id: "bucket_list",
                title: "Bucket List",
                description: "Compare exhilarating milestones and dream adventures.",
                emoji: "📝",
                color: .green,
                questions: [
                    QuizQuestion(id: "bl1", question: "Which bold adventure would we dare together?", options: ["Tandem skydiving", "Scuba diving reefs", "Bungee jumping", "White water rafting"]),
                    QuizQuestion(id: "bl2", question: "A lifestyle bucket list dream:", options: ["Living abroad 6 months", "Attending massive festival", "Restoring a vintage car", "Starting a business duo"]),
                    QuizQuestion(id: "bl3", question: "A cultural celebration we must attend:", options: ["Carnival in Rio", "Lantern festival in Asia", "Times Square countdown", "Oktoberfest in Germany"]),
                    QuizQuestion(id: "bl4", question: "Which milestone will we celebrate biggest?", options: ["Buying our dream house", "10-year anniversary", "Career breakthroughs", "Finishing world tour"]),
                    QuizQuestion(id: "bl5", question: "One goal to achieve in the next 12 months:", options: ["Dream international trip", "Home interior makeover", "Learning a shared skill", "Adopting our dream pet"])
                ]
            ),
            QuizGame(
                id: "our_future",
                title: "Our Future",
                description: "Discuss hopes, growth, and how you want to evolve together.",
                emoji: "🔮",
                color: .pink,
                questions: [
                    QuizQuestion(id: "of1", question: "What will always keep our relationship young?", options: ["Never stopping flirting", "Regular surprise getaways", "Being playful together", "Trying new hobbies"]),
                    QuizQuestion(id: "of2", question: "What yearly tradition should we establish?", options: ["Anniversary getaway trip", "Writing future letters", "Hosting a friend party", "Annual anniversary photo"]),
                    QuizQuestion(id: "of3", question: "How to best support each other's dreams?", options: ["Loudest cheerleader", "Managing things when busy", "Giving honest, gentle advice", "Quiet reassurance"]),
                    QuizQuestion(id: "of4", question: "Core value that anchors our bond:", options: ["Unshakable trust", "Fierce loyalty", "Gentle communication", "Endless laughter"]),
                    QuizQuestion(id: "of5", question: "When looking back decades from now, we will say:", options: ["'We built an incredible life.'", "'We had the most fun.'", "'We stayed true to each other.'", "'We loved with everything.'"])
                ]
            ),
            QuizGame(
                id: "dream_together",
                title: "Dream Together",
                description: "Build an inspirational vision board for your future.",
                emoji: "🌈",
                color: .red,
                questions: [
                    QuizQuestion(id: "dt1", question: "Our favorite Sunday routine in 5 years:", options: ["Brewing coffee with vinyl records", "Morning run & hearty brunch", "Late breakfast in bed", "Working on joint projects"]),
                    QuizQuestion(id: "dt2", question: "Dream world event to attend together:", options: ["Music festival / stadium tour", "World Cup / Olympics final", "Grand red carpet gala", "F1 Grand Prix weekend"]),
                    QuizQuestion(id: "dt3", question: "A creative project to do as a couple:", options: ["Travel vlog / album", "Designing our furniture", "Couple recipe cookbook", "Building a courtyard garden"]),
                    QuizQuestion(id: "dt4", question: "What circle of friends will surround us?", options: ["Tight-knit genuine friends", "Lively social community", "Creative travel companions", "Just close family"]),
                    QuizQuestion(id: "dt5", question: "Secret ingredient to keep love spark alive:", options: ["Spontaneous date nights", "Prioritizing couple time", "Expressing gratitude daily", "Never taking love for granted"])
                ]
            )
        ]
    )
]
