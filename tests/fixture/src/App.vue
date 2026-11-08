<script setup lang="ts">
import { ref } from 'vue'

const label = 'Clicked'
const count = ref(0)
</script>

<template>
  <button type="button" @click="count++">{{ label }} {{ count }} times</button>
</template>
