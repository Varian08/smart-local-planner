import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/auth_guard.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_event.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../favorites/bloc/favorite_bloc.dart';
import '../../../favorites/bloc/favorite_event.dart';
import '../../../favorites/bloc/favorite_state.dart';
import '../../../favorites/presentation/screens/favorite_list_screen.dart';
import '../../bloc/place_bloc.dart';
import '../../bloc/place_event.dart';
import '../../bloc/place_state.dart';
import '../widgets/place_card.dart';

/// Primary Place Discovery Screen implementing the mandatory 4-state UI contract.
/// Features search query input, category filter chips with selected visual states,
/// and responsive place cards with infinite scroll pagination.
class PlaceListScreen extends StatefulWidget {
  const PlaceListScreen({super.key});

  @override
  State<PlaceListScreen> createState() => _PlaceListScreenState();
}

class _PlaceListScreenState extends State<PlaceListScreen> {
  late final ScrollController _scrollController;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.read<AuthBloc>().state is AuthAuthenticated) {
        context.read<FavoriteBloc>().add(const FavoriteFetchStarted());
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<PlaceBloc>().add(const PlaceNextPageFetched());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    // Trigger next page when user has scrolled past 85% of content
    return currentScroll >= (maxScroll * 0.85);
  }

  // ---------------------------------------------------------------------------
  // 1. Screen Scaffold & Reactive State Builder
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.explore_rounded, color: Colors.indigo),
            SizedBox(width: 8),
            Text(
              'Smart Local Planner',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
          ],
        ),
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.white,
        actions: [
          BlocBuilder<FavoriteBloc, FavoriteState>(
            builder: (context, favoriteState) {
              final count = favoriteState is FavoriteLoaded
                  ? favoriteState.favorites.length
                  : 0;

              return IconButton(
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: const Icon(Icons.bookmark_rounded, color: Colors.indigo),
                ),
                tooltip: 'Saved Places',
                onPressed: () {
                  requireAuth(
                    context,
                    message: 'Please sign in to view your saved places.',
                    onAuthenticated: () {
                      if (context.read<FavoriteBloc>().state is FavoriteInitial) {
                        context.read<FavoriteBloc>().add(const FavoriteFetchStarted());
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FavoriteListScreen(),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              if (authState is AuthAuthenticated) {
                return PopupMenuButton<String>(
                  icon: const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.indigo,
                    child: Icon(Icons.person, size: 18, color: Colors.white),
                  ),
                  tooltip: 'Account',
                  onSelected: (value) {
                    if (value == 'logout') {
                      context.read<AuthBloc>().add(const AuthLogoutRequested());
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      enabled: false,
                      child: Text(
                        authState.user?.fullName ?? 'Signed In',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Sign Out', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                icon: const Icon(Icons.login_rounded, size: 18),
                label: const Text('Sign In'),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listener: (context, authState) {
              if (authState is AuthAuthenticated) {
                context.read<FavoriteBloc>().add(const FavoriteFetchStarted());
              } else if (authState is AuthUnauthenticated) {
                context.read<FavoriteBloc>().add(const FavoriteResetRequested());
              }
            },
          ),
          BlocListener<FavoriteBloc, FavoriteState>(
            listener: (context, favoriteState) {
              if (favoriteState is FavoriteLoaded &&
                  favoriteState.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(favoriteState.errorMessage!),
                    backgroundColor: Colors.red.shade700,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ],
        child: Center(
        // Responsive Container constraint: Keeps layout elegant on wide desktop monitors
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              _buildSearchBar(context),
              _buildCategoryFilters(context),
              const SizedBox(height: 8),
              Expanded(
                child: BlocBuilder<PlaceBloc, PlaceState>(
                  builder: (context, state) {
                    // State 1: Loading
                    if (state is PlaceLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // State 2: Empty
                    if (state is PlaceEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_off_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                state.message,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (state.selectedCategory != null ||
                                  state.searchQuery != null) ...[
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    _searchController.clear();
                                    context.read<PlaceBloc>().add(
                                      const PlaceFetchStarted(),
                                    );
                                  },
                                  icon: const Icon(Icons.clear_all_rounded),
                                  label: const Text('Reset filters'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }

                    // State 3: Error with Retry Mechanism
                    if (state is PlaceError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                size: 64,
                                color: Colors.redAccent,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                state.message,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () {
                                  context.read<PlaceBloc>().add(
                                    const PlaceRefreshRequested(),
                                  );
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // State 4: Success Loaded List with Pull-to-Refresh & Infinite Scroll
                    if (state is PlaceLoaded) {
                      return RefreshIndicator(
                        onRefresh: () async {
                          context.read<PlaceBloc>().add(
                            const PlaceRefreshRequested(),
                          );
                        },
                        child: ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16.0),
                          itemCount:
                              state.hasReachedMax
                                  ? state.places.length
                                  : state.places.length + 1,
                          separatorBuilder:
                              (_, _) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            if (index >= state.places.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20.0),
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return PlaceCard(
                              place: state.places[index],
                            );
                          },
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  // ---------------------------------------------------------------------------
  // 2. Search Input Component
  // ---------------------------------------------------------------------------
  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search places, attractions, cafes in Da Nang...',
          prefixIcon: const Icon(Icons.search, color: Colors.indigo),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear, size: 20, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                      context.read<PlaceBloc>().add(
                        const PlaceSearchQueryChanged(''),
                      );
                    },
                  )
                  : null,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onChanged: (_) => setState(() {}),
        onSubmitted: (query) {
          context.read<PlaceBloc>().add(PlaceSearchQueryChanged(query));
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Category Filter Chips Component (Aligned with Backend Enums)
  // ---------------------------------------------------------------------------
  Widget _buildCategoryFilters(BuildContext context) {
    const categories = [
      'ALL',
      'ATTRACTION',
      'CULTURE',
      'NATURE',
      'BEACH',
      'RESTAURANT',
      'CAFE',
    ];

    return BlocBuilder<PlaceBloc, PlaceState>(
      buildWhen: (prev, curr) {
        final prevCat =
            prev is PlaceLoaded
                ? prev.selectedCategory
                : (prev is PlaceEmpty ? prev.selectedCategory : null);
        final currCat =
            curr is PlaceLoaded
                ? curr.selectedCategory
                : (curr is PlaceEmpty ? curr.selectedCategory : null);
        return prevCat != currCat;
      },
      builder: (context, state) {
        final activeCategory =
            state is PlaceLoaded
                ? state.selectedCategory
                : (state is PlaceEmpty ? state.selectedCategory : null);

        return SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected =
                  (cat == 'ALL' && activeCategory == null) ||
                  (cat == activeCategory);

              return FilterChip(
                label: Text(
                  cat,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 12,
                    color:
                        isSelected
                            ? Colors.indigo.shade900
                            : Colors.grey.shade700,
                  ),
                ),
                selected: isSelected,
                showCheckmark: false,
                selectedColor: Colors.indigo.shade50,
                backgroundColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? Colors.indigo : Colors.grey.shade300,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                onSelected: (_) {
                  final target =
                      cat == 'ALL' ? null : (isSelected ? null : cat);
                  context.read<PlaceBloc>().add(PlaceCategoryChanged(target));
                },
              );
            },
          ),
        );
      },
    );
  }
}
