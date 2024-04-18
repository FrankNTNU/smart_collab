import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_collab/services/auth_controller.dart';

import 'team_controller.dart';

class Comment {
  final String id;
  final String issueId;
  final String userId;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.issueId,
    required this.userId,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      issueId: json['issueId'],
      userId: json['userId'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class CommentsState {
  final List<Comment> comments;
  final String userId;
  final ApiStatus apiStatus;
  final PerformedAction performedAction;
  final String? errorMessage;
  final DocumentSnapshot? lastDocRef;
  // ctor
  CommentsState({
    required this.comments,
    required this.userId,
    required this.apiStatus,
    required this.performedAction,
    this.errorMessage,
    required this.lastDocRef,
  });
  // copyWith
  CommentsState copyWith({
    List<Comment>? comments,
    String? userId,
    ApiStatus? apiStatus,
    PerformedAction? performedAction,
    String? errorMessage,
    DocumentSnapshot? lastDocRef,
  }) {
    return CommentsState(
      comments: comments ?? this.comments,
      userId: userId ?? this.userId,
      apiStatus: apiStatus ?? this.apiStatus,
      performedAction: performedAction ?? this.performedAction,
      errorMessage: errorMessage,
      lastDocRef: lastDocRef ?? this.lastDocRef,
    );
  }

  // initial
  static CommentsState initial() {
    return CommentsState(
      comments: [],
      userId: '',
      apiStatus: ApiStatus.idle,
      performedAction: PerformedAction.fetch,
      lastDocRef: null,
      errorMessage: '',
    );
  }
}

class CommentController
    extends AutoDisposeFamilyNotifier<CommentsState, String> {
  @override
  CommentsState build(String arg) {
    final userId =
        ref.watch(authControllerProvider.select((value) => value.user?.uid));
    return CommentsState.initial().copyWith(userId: userId);
  }

  Future<void> deleteComment(String commentId, String issueId) async {
    // delete the comment from issues/{issueId}/comments/{commentId}
    // set loading
    state = state.copyWith(
        apiStatus: ApiStatus.loading, performedAction: PerformedAction.delete);
    try {
      await FirebaseFirestore.instance
          .collection('issues')
          .doc(issueId)
          .collection('comments')
          .doc(commentId)
          .delete();
      // remove the comment from the state
      final comments =
          state.comments.where((comment) => comment.id != commentId);
      state = state.copyWith(
        comments: comments.toList(),
        apiStatus: ApiStatus.success,
      );
    } catch (e) {
      print('Error deleting comment: $e');
      state = state.copyWith(
        apiStatus: ApiStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> addComment(String content) async {
    // add the comment to issues/{issueId}/comments
    // set loading
    state = state.copyWith(
        apiStatus: ApiStatus.loading, performedAction: PerformedAction.add);
    try {
      final docRef = await FirebaseFirestore.instance
          .collection('issues')
          .doc(arg)
          .collection('comments')
          .add({
        'userId': state.userId,
        'content': content,
        'issueId': arg,
        'createdAt': DateTime.now().toIso8601String(),
      });
      // add the comment to the state
      // get the newly added comment
      final snapShot = await docRef.get();
      final data = snapShot.data()!;
      final newComment = Comment(
        id: snapShot.id,
        issueId: arg,
        userId: data['userId'],
        content: data['content'],
        createdAt: DateTime.parse(data['createdAt']),
      );
      state = state.copyWith(
        comments: [...state.comments, newComment],
        apiStatus: ApiStatus.success,
      );
    } catch (e) {
      print('Error adding comment: $e');
      state = state.copyWith(
        apiStatus: ApiStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> fetchComments(String issueId) async {
    const limit = 5;
    // fetch the comments from issues/{issueId}/comments
    // set loading
    state = state.copyWith(
        apiStatus: ApiStatus.loading, performedAction: PerformedAction.fetch);
    try {
      final snapShot = state.lastDocRef != null
          ? await FirebaseFirestore.instance
              .collection('issues')
              .doc(issueId)
              .collection('comments')
              .startAfterDocument(state.lastDocRef!)
              .limit(limit)
              .get()
          : await FirebaseFirestore.instance
              .collection('issues')
              .doc(issueId)
              .collection('comments')
              .limit(limit)
              .get();
      // get the last document reference
      final lastDocRef = snapShot.docs.isNotEmpty ? snapShot.docs.last : null;
      state = state.copyWith(lastDocRef: lastDocRef);
      final comments = snapShot.docs.map((doc) {
        final data = doc.data();
        return Comment(
          id: doc.id,
          issueId: issueId,
          userId: data['userId'],
          content: data['content'],
          createdAt: DateTime.parse(data['createdAt']),
        );
      }).toList();
      state = state.copyWith(
        comments: comments,
        apiStatus: ApiStatus.success,
      );
    } catch (e) {
      print('Error fetching comments: $e');
      state = state.copyWith(
        apiStatus: ApiStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}

final commentProvider = NotifierProvider.autoDispose
    .family<CommentController, CommentsState, String>(
  () => CommentController(),
);
