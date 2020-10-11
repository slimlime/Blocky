//
//  FilterListViewModel.swift
//  Blocky
//
//  Created by Max Chuquimia on 8/10/20.
//  Copyright © 2020 Chuquimian Productions. All rights reserved.
//

import Foundation
import Combine

protocol FilterListController {
    var viewState: Variable<FilterList.ViewState> { get }
    func reorder(a: IndexPath, to b: IndexPath)
    func save(filter: Filter)
    func delete(filter: Filter)
}

extension FilterList {

    class Controller: FilterListController {

        internal var viewState: Variable<ViewState> = .init(value: .initial)

        private var enabledFilters: [Filter] = []
        private var disabledFilters: [Filter] = []
        private let filterDataSource: FilterDataSourceInterface

        init(filterDataSource: FilterDataSourceInterface = FilterDataSource()) {
            self.filterDataSource = filterDataSource

            presentFilters()
        }

    }

}

extension FilterList.Controller {

    func reorder(a: IndexPath, to b: IndexPath) {
        let targetItem: Filter

        if a.section == 0 {
            targetItem = enabledFilters.remove(at: a.row)
        } else {
            targetItem = disabledFilters.remove(at: a.row)
        }

        if b.section == 0 {
            enabledFilters.insert(targetItem, at: b.row)
        } else {
            disabledFilters.insert(targetItem, at: b.row)
        }

        // Re-compute .isEnabled and .order
        enabledFilters = enabledFilters
            .enumerated()
            .map {
                Filter(
                    identifier: $1.identifier,
                    name: $1.name,
                    rule: $1.rule,
                    isCaseSensitive: $1.isCaseSensitive,
                    isEnabled: true,
                    order: $0
                )
            }

        disabledFilters = disabledFilters
            .enumerated()
            .map {
                Filter(
                    identifier: $1.identifier,
                    name: $1.name,
                    rule: $1.rule,
                    isCaseSensitive: $1.isCaseSensitive,
                    isEnabled: false,
                    order: $0
                )
            }

        storeFilters()
        presentFilters()
    }

    func save(filter: Filter) {
        var allFilters = filterDataSource.readFilters()

        // Replace existing filter if possible
        if let idx = allFilters.firstIndex(where: { $0.identifier == filter.identifier }) {
            allFilters[idx] = filter
        } else {
            allFilters.append(filter)
        }

        filterDataSource.write(filters: allFilters)

        presentFilters()
    }

    func delete(filter: Filter) {
        var allFilters = filterDataSource.readFilters()
        allFilters.removeAll(where: { $0.identifier == filter.identifier })

        filterDataSource.write(filters: allFilters)

        presentFilters()
    }

}

private extension FilterList.Controller {

    func readFilters() {
        let allFilters = filterDataSource.readFilters()

        enabledFilters = allFilters
            .filter(\.isEnabled)
            .sorted(by: { $0.order < $1.order })

        disabledFilters = allFilters
            .filter({ !$0.isEnabled })
            .sorted(by: { $0.order < $1.order })
    }

    func storeFilters() {
        filterDataSource.write(filters: enabledFilters + disabledFilters)
    }

    func presentFilters() {
        readFilters()

        let viewConfiguration = FilterList.ViewState.Configuration(
            enabledFilters: enabledFilters,
            disabledFilters: disabledFilters,
            isEnabledInSettings: false
        )

        viewState.value = .loaded(viewConfiguration)
    }

}
