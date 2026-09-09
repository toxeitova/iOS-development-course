let firstName: String = "Aruzhan"
let lastName: String = "Tokseitova"
let age: Int = 21
let birthYear: Int = 2005
let isStudent: Bool = true
let height: Double = 1.65

let currentYear: Int = 2026
let calculatedAge = currentYear - birthYear

let hobby: String = "content creation"
let numberOfHobbies: Int = 5
let favoriteNumber: Int = 8
let isHobbyCreative: Bool = true

let lifeStory = "My name is \(firstName) \(lastName). I am \(age) years old, born in \(birthYear). I am currently a student: \(isStudent). My height is \(height)m. I enjoy \(hobby), which is a creative hobby: \(isHobbyCreative). I have \(numberOfHobbies) hobbies in total, and my favorite number is \(favoriteNumber)."

print(lifeStory)

let futureGoals: String = "get into a MAANG company"
let ambitionEmoji = "🚀"

let fullStory = lifeStory + " In the future, I want to \(futureGoals). \(ambitionEmoji)"
print(fullStory)
