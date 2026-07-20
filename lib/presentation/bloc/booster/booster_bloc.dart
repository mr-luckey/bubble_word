import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/enums.dart';
import '../../../domain/entities/economy_state.dart';
import '../economy/economy_bloc.dart';
import '../game/game_bloc.dart';

part 'booster_event.dart';
part 'booster_state.dart';

class BoosterBloc extends Bloc<BoosterEvent, BoosterBlocState> {
  BoosterBloc(this._economyBloc, this._gameBloc) : super(const BoosterBlocState()) {
    on<UseHint>(_onHint);
    on<UseMagnet>(_onMagnet);
    on<UseAddBall>(_onAddBall);
    on<UseMagicWand>(_onMagicWand);
    on<UseExtraMoves>(_onExtraMoves);
    on<ClearBoosterMessage>(_onClearMessage);
  }

  final EconomyBloc _economyBloc;
  final GameBloc _gameBloc;

  BoosterInventory get _inventory => _economyBloc.state.economy.boosters;

  Future<void> _updateInventory(BoosterInventory inv) async {
    _economyBloc.add(UpdateBoosters(inv));
  }

  void _emitMessage(Emitter<BoosterBlocState> emit, String message) {
    emit(BoosterBlocState(message: message));
    emit(const BoosterBlocState());
  }

  Future<void> _onClearMessage(
    ClearBoosterMessage event,
    Emitter<BoosterBlocState> emit,
  ) async {
    emit(const BoosterBlocState());
  }

  Future<void> _onHint(UseHint event, Emitter<BoosterBlocState> emit) async {
    if (!_inventory.freeHintUsedThisLevel) {
      _gameBloc.add(const ApplyHint());
      await _updateInventory(_inventory.copyWith(freeHintUsedThisLevel: true));
      emit(BoosterBlocState(activeBooster: BoosterType.hint));
      emit(const BoosterBlocState());
      return;
    }
    if (_inventory.hint <= 0) {
      _emitMessage(emit, 'No hints left');
      return;
    }
    _gameBloc.add(const ApplyHint());
    await _updateInventory(_inventory.copyWith(hint: _inventory.hint - 1));
    emit(BoosterBlocState(activeBooster: BoosterType.hint));
    emit(const BoosterBlocState());
  }

  Future<void> _onMagnet(UseMagnet event, Emitter<BoosterBlocState> emit) async {
    if (_inventory.magnet <= 0) {
      _emitMessage(emit, 'No magnets left');
      return;
    }
    _gameBloc.add(ApplyMagnet(event.wordId));
    await _updateInventory(_inventory.copyWith(magnet: _inventory.magnet - 1));
    emit(BoosterBlocState(activeBooster: BoosterType.magnet));
    emit(const BoosterBlocState());
  }

  Future<void> _onAddBall(UseAddBall event, Emitter<BoosterBlocState> emit) async {
    if (!_inventory.freeAddBallUsedThisLevel) {
      _gameBloc.add(const ApplyAddBall());
      await _updateInventory(_inventory.copyWith(freeAddBallUsedThisLevel: true));
      emit(BoosterBlocState(activeBooster: BoosterType.addBall));
      emit(const BoosterBlocState());
      return;
    }
    if (_inventory.addBall <= 0) {
      _emitMessage(emit, 'No add-ball boosters left');
      return;
    }
    _gameBloc.add(const ApplyAddBall());
    await _updateInventory(_inventory.copyWith(addBall: _inventory.addBall - 1));
    emit(BoosterBlocState(activeBooster: BoosterType.addBall));
    emit(const BoosterBlocState());
  }

  Future<void> _onMagicWand(UseMagicWand event, Emitter<BoosterBlocState> emit) async {
    if (_inventory.magicWand <= 0) {
      _emitMessage(emit, 'No magic wands left');
      return;
    }
    final gameState = _gameBloc.state;
    if (gameState is! GamePlaying ||
        gameState.gameState.lastWrongMergeBallId == null) {
      _emitMessage(emit, 'No junk ball to split');
      return;
    }
    _gameBloc.add(const ApplyMagicWand());
    await _updateInventory(
      _inventory.copyWith(magicWand: _inventory.magicWand - 1),
    );
    emit(BoosterBlocState(activeBooster: BoosterType.magicWand));
    emit(const BoosterBlocState());
  }

  Future<void> _onExtraMoves(UseExtraMoves event, Emitter<BoosterBlocState> emit) async {
    if (!_inventory.freeExtraMovesUsedThisLevel) {
      _gameBloc.add(const AddExtraMoves());
      await _updateInventory(_inventory.copyWith(freeExtraMovesUsedThisLevel: true));
      emit(BoosterBlocState(activeBooster: BoosterType.extraMoves));
      emit(const BoosterBlocState());
      return;
    }
    if (_inventory.extraMoves <= 0) {
      _emitMessage(emit, 'No extra-move boosters left');
      return;
    }
    _gameBloc.add(const AddExtraMoves());
    await _updateInventory(
      _inventory.copyWith(extraMoves: _inventory.extraMoves - 1),
    );
    emit(BoosterBlocState(activeBooster: BoosterType.extraMoves));
    emit(const BoosterBlocState());
  }
}
