<script>
/* eslint-disable vue/require-default-prop */
import IssueCardInner from './issue_card_inner.vue';
import boardsStore from '../stores/boards_store';

export default {
  name: 'BoardsIssueCard',
  components: {
    IssueCardInner,
  },
  props: {
    list: {
      type: Object,
      default: () => ({}),
      required: false,
    },
    issue: {
      type: Object,
      default: () => ({}),
      required: false,
    },
    issueLinkBase: {
      type: String,
      default: '',
      required: false,
    },
    disabled: {
      type: Boolean,
      default: false,
      required: false,
    },
    index: {
      type: Number,
      default: 0,
      required: false,
    },
    rootPath: {
      type: String,
      default: '',
      required: false,
    },
    groupId: {
      type: Number,
      required: false,
    },
    isActive: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      showDetail: false,
      multiSelect: boardsStore.multiSelect,
    };
  },
  computed: {
    multiSelectVisible() {
      return this.multiSelect.list.findIndex(issue => issue.id === this.issue.id) > -1;
    },
    canMultiSelect() {
      return gon.features && gon.features.multiSelectBoard;
    },
  },
  methods: {
    mouseDown() {
      this.showDetail = true;
    },
    mouseMove() {
      this.showDetail = false;
    },
    showIssue(e) {
      // Don't do anything if this happened on a no trigger element
      if (e.target.classList.contains('js-no-trigger')) return;

      const isMultiSelect = this.canMultiSelect && (e.ctrlKey || e.metaKey);

      if (this.showDetail || isMultiSelect) {
        this.showDetail = false;
        this.$emit('show', { event: e, isMultiSelect });
      }
    },
  },
};
</script>

<template>
  <li
    :class="{
      'multi-select': multiSelectVisible,
      'user-can-drag': !disabled && issue.id,
      'is-disabled': disabled || !issue.id,
      'is-active': isActive,
    }"
    :index="index"
    :data-issue-id="issue.id"
    data-testid="board_card"
    class="board-card p-3 rounded"
    @mousedown="mouseDown"
    @mousemove="mouseMove"
    @mouseup="showIssue($event)"
  >
    <issue-card-inner
      :list="list"
      :issue="issue"
      :issue-link-base="issueLinkBase"
      :group-id="groupId"
      :root-path="rootPath"
      :update-filters="true"
    />
  </li>
</template>
