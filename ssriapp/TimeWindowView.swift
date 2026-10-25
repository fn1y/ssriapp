import SwiftUI

struct TimeWindowView: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { _ in
            VStack{
                HStack{
                    Text("Time Window")
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Until 11:33")
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
                                .offset(x:140)
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
                
                
                
                
                Text("To maintain a consistent level, in your blood and mood, you should take your meds now. This is a dummy widget.")
                    .font(.caption)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }
            .padding(.vertical)
            .glassEffect(in: .rect(cornerRadius: 30.0))
//            .cornerRadius(24)
            .padding()
        }
    }
}

#Preview{
    TimeWindowView()
}
