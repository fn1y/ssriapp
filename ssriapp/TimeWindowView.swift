import SwiftUI

struct TimeWindowView: View {
    var xOffset: Int = 150
    var statusText: String = "Until 11:33"
    var encouragementText: String = ""

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { _ in
            VStack{
                HStack{
                    Text("Time Window")
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(statusText)
                        .contentTransition(.numericText(countsDown: true))
                        .animation(.smooth(duration: 0.5), value: statusText)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                }
                .padding(.horizontal)
                
                
                ZStack{
                    //Timeline
                    Color.clear
                        .frame(height: 40)
                        .overlay(alignment: .center) {
                            ZStack{
                                HStack{
                                    ForEach(0..<40, id: \.self) { index in
                                        Rectangle()
                                            .frame(width:4)
                                            .cornerRadius(10)
                                        .opacity(0.4)}
                                    Rectangle()
                                        .fill(.linearGradient(
                                            colors: [.teal, .green],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ))
                                        .frame(width: 300, height: 40)
                                        .cornerRadius(7)
                                    ForEach(0..<40, id: \.self) { index in
                                        Rectangle()
                                            .frame(width:4)
                                            .cornerRadius(10)
                                        .opacity(0.4)}
                                }
                                .offset(x: CGFloat(xOffset))
                                .animation(.smooth(duration: 0.5), value: xOffset)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 0))
                        .mask {
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0),
                                    .init(color: .black, location: 0.30),
                                    .init(color: .black, location: 0.70),
                                    .init(color: .clear, location: 1)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        }
                        .padding(.vertical, 6)
                    
                    //Overlay thing
                    Rectangle()
                        .frame(width:8, height:50)
                        .cornerRadius(10)
                        .glassEffect()
                    
                }
                
                
                
                
                if !encouragementText.isEmpty {
                    Text(encouragementText)
                        .contentTransition(.numericText())
                        .animation(.smooth(duration: 0.5), value: encouragementText)
                        .font(.caption)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                }
            }
//            .padding(.vertical)
//            .glassEffect(in: .rect(cornerRadius: 30.0))
////            .cornerRadius(24)
//            .padding()
        }
    }
}

func timeWindowOffset(startHour: Int, startMinute: Int, pillWidth: Int, now: Date = .now) -> Int{
    //get current time
    let calendar = Calendar.current
    let hour = calendar.component(.hour, from: now)
    let minute = calendar.component(.minute, from: now)
    
    let currentMinutes = hour * 60 + minute
    let startMinutes = startHour * 60 + startMinute
    
    let difference = startMinutes - currentMinutes
    
    print("Current difference is ", difference)
    
    // Half the pill represents the 60 minutes on either side of the target.
    let minutesEitherSide = 60.0
    let startX = Double(pillWidth) / 2
    let multiplier = startX / minutesEitherSide
    
    //if difference is 0 we are bang on the target time
    //anything + or - 0 is how far we should be from the middle of the pill
    let finalOffset = Double(difference) * multiplier
    
    return Int(finalOffset.rounded())
    
}

func timeWindowLabel(targetTime: Date, now: Date) -> String {
    let windowStart = targetTime.addingTimeInterval(-3600)
    let windowEnd = targetTime.addingTimeInterval(3600)
    let endText = windowEnd.formatted(date: .omitted, time: .shortened)

    if now < windowStart {
        // Round up so the countdown never says zero minutes before the window opens
        let minutes = Int(ceil(windowStart.timeIntervalSince(now) / 60))
        if minutes/60 > 0{
            return "In \(minutes / 60) hr \(minutes % 60) min"
        } else{
            return "In \(minutes) min"
        }
    } else if now < windowEnd {
        return "Until \(endText)"
    } else {
        return "Ended \(endText)"
    }
}

func timeWindowText(targetTime: Date, now: Date) -> String {
    let windowStart = targetTime.addingTimeInterval(-3600)
    let windowEnd = targetTime.addingTimeInterval(3600)

    if now < windowStart {
        return("For the best consistency, you should wait before taking your medication.")
    } else if now < windowEnd {
        return "To maintain a consistent level, in your blood and mood, it's a good idea to take your meds now."
    } else {
        return "You missed your window, but late is better than never!"
    }
}

private struct TimeWindowPreview: View {
    @State private var medicationTime = Date()

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let calendar = Calendar.current
            let offset = timeWindowOffset(
                startHour: calendar.component(.hour, from: medicationTime),
                startMinute: calendar.component(.minute, from: medicationTime),
                pillWidth: 300,
                now: context.date
            )

            VStack {
                DatePicker(
                    "Medication time",
                    selection: $medicationTime,
                    displayedComponents: .hourAndMinute
                )
                .padding(.horizontal)

                Stepper("Adjust by 15 minutes") {
                    medicationTime = medicationTime.addingTimeInterval(15 * 60)
                } onDecrement: {
                    medicationTime = medicationTime.addingTimeInterval(-15 * 60)
                }
                .padding(.horizontal)

                Text("Current time: \(context.date.formatted(date: .omitted, time: .shortened))")
                    .foregroundStyle(.secondary)

                TimeWindowView(
                    xOffset: offset,
                    statusText: timeWindowLabel(targetTime: medicationTime, now: context.date),
                    encouragementText: timeWindowText(targetTime: medicationTime, now: context.date)
                )

                Text("X offset: \(offset)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    TimeWindowPreview()
}
