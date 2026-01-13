//
//  CosmeticsView.swift
//  AmazingGirlCosmetic
//
//  Created by Алексей Авер on 17.12.2025.
//

import SwiftUI

struct CosmeticsView: View {
    @EnvironmentObject private var store: BeautyStore
    @State private var showAdd = false
    @State private var showEdit = false
    @State private var selectedItem: CosmeticItem? = nil

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 22),
        GridItem(.flexible(), spacing: 22)
    ]
    
    private let horizontalPadding: CGFloat = 20
    private let topPadding: CGFloat = 18
    
    private let floatingTabBarHeight: CGFloat = 70
    private let floatingTabBarOuterBottomPadding: CGFloat = 6
    private let floatingTabBarExtraSafeGap: CGFloat = 22
    
    private var scrollBottomPadding: CGFloat {
        floatingTabBarHeight + floatingTabBarOuterBottomPadding + floatingTabBarExtraSafeGap
    }
    
    
    
    var body: some View {
        ZStack {
            AppColor.background.edgesIgnoringSafeArea(.all)
            
            VStack {
                AppNavBar(title: "Cosmetics", onBack: nil) {
                    showAdd.toggle()
                }
                
                if store.cosmetics.isEmpty {
                    VStack {
                        Spacer()
                        Text("Your collection is empty for now.\nAdd your first cosmetic item and start tracking!")
                            .font(AppFont.make(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 24) {
                            ForEach(store.cosmetics) { item in
                                CosmeticCard(item: item)
                                    .onTapGesture {
                                        selectedItem = item
                                        showEdit.toggle()
                                    }
                            }
                        }
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, topPadding)
                        .padding(.bottom, scrollBottomPadding)
                    }
                }
            }
        }
        .navigationDestination(isPresented: $showAdd) {
            AddEditCosmeticsView(mode: .add)
                .environmentObject(store)
                .navigationBarBackButtonHidden()
        }
        
        .navigationDestination(isPresented: $showEdit) {
            if let selectedItem {
                AddEditCosmeticsView(mode: .edit(selectedItem))
                    .environmentObject(store)
                    .navigationBarBackButtonHidden()
            }
        }
    }
}

#Preview {
    NavigationStack {
        CosmeticsView()
            .environmentObject(BeautyStore())
    }
}
