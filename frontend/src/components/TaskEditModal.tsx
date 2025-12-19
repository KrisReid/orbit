import { useState, useRef } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '@/api/client';
import type { Task, TaskType, Team, Project } from '@/types';
import { GitBranch, ChevronDown, X, ArrowRight, ArrowLeft, Plus, CheckSquare } from 'lucide-react';
import {
  WorkflowSelector,
  DynamicField,
  SelectInput,
  FormModal,
  EmptyState,
} from './ui';
import { useDropdownClose } from '@/hooks';

interface TaskEditModalProps {
  task: Task;
  teams: Team[];
  taskTypes: TaskType[];
  projects: Project[];
  allTasks: Task[];
  onClose: () => void;
  onTaskUpdated: () => void;
}

export function TaskEditModal({
  task,
  teams,
  taskTypes,
  projects,
  allTasks,
  onClose,
  onTaskUpdated,
}: TaskEditModalProps) {
  const queryClient = useQueryClient();
  
  // Fetch full task details including dependencies
  const { data: fullTask } = useQuery({
    queryKey: ['task', task.id],
    queryFn: () => api.tasks.get(task.id),
    initialData: task,
  });

  // Fetch task type with fields
  const { data: taskTypeWithFields } = useQuery({
    queryKey: ['taskType', task.task_type_id],
    queryFn: () => api.taskTypes.get(task.task_type_id),
  });

  // Fetch releases
  const { data: releases } = useQuery({
    queryKey: ['releases'],
    queryFn: () => api.releases.list(),
  });

  // Fetch all tasks (across all teams) for dependency selection
  const { data: allTasksData } = useQuery({
    queryKey: ['allTasksForDependencies'],
    queryFn: () => api.tasks.list({ page_size: 500 }),
  });

  // Form state
  const [title, setTitle] = useState(task.title);
  const [description, setDescription] = useState(task.description || '');
  const [status, setStatus] = useState(task.status);
  const [estimation, setEstimation] = useState<number | null>(task.estimation);
  const [projectId, setProjectId] = useState<number | null>(task.project_id);
  const [releaseId, setReleaseId] = useState<number | null>(task.release_id);
  const [, teamId] = useState(task.team_id);
  const [taskTypeId, setTaskTypeId] = useState(task.task_type_id);
  const [customData, setCustomData] = useState<Record<string, unknown>>(task.custom_data || {});
  
  // Dropdown and modal states
  const [showTeamDropdown, setShowTeamDropdown] = useState(false);
  const [showTaskTypeDropdown, setShowTaskTypeDropdown] = useState(false);
  const [showAddDependencyModal, setShowAddDependencyModal] = useState(false);

  const teamDropdownRef = useRef<HTMLDivElement>(null);
  const taskTypeDropdownRef = useRef<HTMLDivElement>(null);

  // Use click outside hook for dropdowns
  useDropdownClose([
    { ref: teamDropdownRef, isOpen: showTeamDropdown, close: () => setShowTeamDropdown(false) },
    { ref: taskTypeDropdownRef, isOpen: showTaskTypeDropdown, close: () => setShowTaskTypeDropdown(false) },
  ]);

  // Get current workflow based on selected task type
  const currentTaskType = taskTypes.find(tt => tt.id === taskTypeId);
  const workflow = currentTaskType?.workflow || [];

  // Fetch all task types for team switching
  const { data: allTaskTypes } = useQuery({
    queryKey: ['allTaskTypes'],
    queryFn: () => api.taskTypes.list({}),
  });

  // Update mutation
  const updateMutation = useMutation({
    mutationFn: (data: {
      title?: string;
      description?: string | null;
      status?: string;
      estimation?: number | null;
      project_id?: number | null;
      release_id?: number | null;
      team_id?: number;
      task_type_id?: number;
      custom_data?: Record<string, unknown>;
    }) => api.tasks.update(task.id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['tasks'] });
      queryClient.invalidateQueries({ queryKey: ['task', task.id] });
      queryClient.invalidateQueries({ queryKey: ['taskTypes'] });
      queryClient.invalidateQueries({ queryKey: ['project'] });
      queryClient.invalidateQueries({ queryKey: ['projects'] });
      queryClient.invalidateQueries({ queryKey: ['allTasksForLinking'] });
    },
  });

  // Dependency mutations
  const addDependencyMutation = useMutation({
    mutationFn: (dependsOnId: number) => api.addTaskDependency(task.id, dependsOnId),
    onSuccess: (_, dependsOnId) => {
      // Invalidate current task, the other task, and all task lists for refresh
      queryClient.invalidateQueries({ queryKey: ['task', task.id] });
      queryClient.invalidateQueries({ queryKey: ['task', dependsOnId] });
      queryClient.invalidateQueries({ queryKey: ['tasks'] });
      queryClient.invalidateQueries({ queryKey: ['allTasksForDependencies'] });
    },
  });

  const removeDependencyMutation = useMutation({
    mutationFn: (dependsOnId: number) => api.removeTaskDependency(task.id, dependsOnId),
    onSuccess: (_, dependsOnId) => {
      // Invalidate current task, the other task, and all task lists for refresh
      queryClient.invalidateQueries({ queryKey: ['task', task.id] });
      queryClient.invalidateQueries({ queryKey: ['task', dependsOnId] });
      queryClient.invalidateQueries({ queryKey: ['tasks'] });
      queryClient.invalidateQueries({ queryKey: ['allTasksForDependencies'] });
    },
  });

  const handleFieldChange = (field: string, value: unknown) => {
    updateMutation.mutate({ [field]: value });
  };

  const handleCustomFieldChange = (key: string, value: unknown) => {
    const newCustomData = { ...customData, [key]: value };
    setCustomData(newCustomData);
    handleFieldChange('custom_data', newCustomData);
  };

  // Available tasks for dependencies (exclude self and already added)
  // Use allTasksData to allow dependencies across teams
  const existingDependencyIds = fullTask?.dependencies?.map(d => d.id) || [];
  const allAvailableTasks = allTasksData?.items || allTasks; // Fallback to passed allTasks if fetch fails
  const availableTasksForDependency = allAvailableTasks.filter(
    t => t.id !== task.id && !existingDependencyIds.includes(t.id)
  );

  const selectedTeam = teams.find(t => t.id === teamId);
  const selectedTaskType = taskTypes.find(tt => tt.id === taskTypeId);

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="flex min-h-screen items-center justify-center p-4">
        <div className="fixed inset-0 bg-black/50" onClick={onClose} />
        <div className="relative bg-white dark:bg-gray-800 rounded-xl shadow-xl max-w-4xl w-full max-h-[90vh] overflow-hidden flex flex-col">
          {/* Header */}
          <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200 dark:border-gray-700">
            <div className="flex items-center gap-4">
              {/* Task ID */}
              <span className="font-mono text-sm text-gray-500 dark:text-gray-400 bg-gray-100 dark:bg-gray-700 px-2 py-1 rounded">
                {task.display_id}
              </span>
              
              {/* Team Dropdown */}
              <div className="relative" ref={teamDropdownRef}>
                <button
                  onClick={() => setShowTeamDropdown(!showTeamDropdown)}
                  className="flex items-center gap-1 text-sm font-medium text-primary-600 hover:text-primary-700"
                >
                  {selectedTeam?.name || 'Select Team'}
                  <ChevronDown className="h-4 w-4" />
                </button>
                {showTeamDropdown && (
                  <div className="absolute top-full left-0 mt-1 w-48 bg-white dark:bg-gray-800 rounded-lg shadow-lg border border-gray-200 dark:border-gray-700 z-10 py-1">
                    {teams.map(team => (
                      <button
                        key={team.id}
                        onClick={() => {
                          if (team.id === teamId) {
                            setShowTeamDropdown(false);
                            return;
                          }
                          
                          const newTeamTaskTypes = (allTaskTypes?.items || []).filter(tt => tt.team_id === team.id);
                          const newTaskType = newTeamTaskTypes[0];
                          
                          if (newTaskType) {
                            const newWorkflow = newTaskType.workflow || [];
                            const newStatus = newWorkflow[0] || 'Backlog';
                            
                            updateMutation.mutate({
                              team_id: team.id,
                              task_type_id: newTaskType.id,
                              status: newStatus,
                            }, {
                              onSuccess: () => {
                                onTaskUpdated();
                              }
                            });
                          }
                          setShowTeamDropdown(false);
                        }}
                        disabled={!allTaskTypes?.items}
                        className={`w-full px-4 py-2 text-left text-sm hover:bg-gray-100 dark:hover:bg-gray-700 flex items-center gap-2 ${
                          team.id === teamId ? 'text-primary-600 dark:text-primary-400 font-medium' : 'text-gray-700 dark:text-gray-300'
                        }`}
                      >
                        {team.id === teamId && <span>✓</span>}
                        {team.name}
                      </button>
                    ))}
                  </div>
                )}
              </div>

              <span className="text-gray-300 dark:text-gray-600">›</span>

              {/* Task Type Dropdown */}
              <div className="relative" ref={taskTypeDropdownRef}>
                <button
                  onClick={() => setShowTaskTypeDropdown(!showTaskTypeDropdown)}
                  className="flex items-center gap-1 text-sm font-medium text-gray-700 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white"
                >
                  {selectedTaskType?.name || 'Select Type'}
                  <ChevronDown className="h-4 w-4" />
                </button>
                {showTaskTypeDropdown && (
                  <div className="absolute top-full left-0 mt-1 w-48 bg-white dark:bg-gray-800 rounded-lg shadow-lg border border-gray-200 dark:border-gray-700 z-10 py-1">
                    {(allTaskTypes?.items || taskTypes).filter(tt => tt.team_id === teamId).map(taskType => (
                      <button
                        key={taskType.id}
                        onClick={() => {
                          if (taskType.id === taskTypeId) {
                            setShowTaskTypeDropdown(false);
                            return;
                          }
                          
                          const newWorkflow = taskType.workflow || [];
                          const newStatus = newWorkflow.includes(status) ? status : newWorkflow[0] || 'Backlog';
                          
                          if (newStatus !== status) {
                            updateMutation.mutate({
                              task_type_id: taskType.id,
                              status: newStatus,
                            });
                            setStatus(newStatus);
                          } else {
                            updateMutation.mutate({ task_type_id: taskType.id });
                          }
                          
                          setTaskTypeId(taskType.id);
                          setShowTaskTypeDropdown(false);
                        }}
                        className={`w-full px-4 py-2 text-left text-sm hover:bg-gray-100 dark:hover:bg-gray-700 flex items-center gap-2 ${
                          taskType.id === taskTypeId ? 'text-primary-600 dark:text-primary-400 font-medium' : 'text-gray-700 dark:text-gray-300'
                        }`}
                      >
                        {taskType.id === taskTypeId && <span>✓</span>}
                        {taskType.name}
                      </button>
                    ))}
                  </div>
                )}
              </div>
            </div>

            {/* Close Button */}
            <button
              onClick={onClose}
              className="p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700"
            >
              <X className="h-5 w-5" />
            </button>
          </div>

          {/* Content */}
          <div className="flex-1 overflow-y-auto p-6">
            {/* Task Title */}
            <input
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              onBlur={() => {
                if (title !== task.title) {
                  handleFieldChange('title', title);
                }
              }}
              className="w-full text-2xl font-bold text-gray-900 dark:text-white bg-transparent border-none focus:outline-none focus:ring-0 mb-6"
              placeholder="Task title..."
            />

            <div className="grid grid-cols-3 gap-8">
              {/* Left Column - Description, Project, Custom Fields */}
              <div className="col-span-2 space-y-6">
                {/* Description */}
                <div>
                  <label className="block text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-2">
                    Description
                  </label>
                  <textarea
                    value={description}
                    onChange={(e) => setDescription(e.target.value)}
                    onBlur={() => {
                      if (description !== (task.description || '')) {
                        handleFieldChange('description', description || null);
                      }
                    }}
                    placeholder="Add a description..."
                    rows={6}
                    className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white text-sm resize-none"
                  />
                </div>

                {/* Associated Project */}
                <div>
                  <label className="block text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-2">
                    Associated Project
                  </label>
                  <SelectInput
                    value={projectId || ''}
                    onChange={(e) => {
                      const newProjectId = e.target.value ? Number(e.target.value) : null;
                      setProjectId(newProjectId);
                      handleFieldChange('project_id', newProjectId);
                    }}
                    options={projects.map(p => ({ value: p.id, label: p.title }))}
                    placeholder="No Project"
                  />
                </div>

                {/* Custom Fields - using DynamicField component */}
                {taskTypeWithFields?.fields && taskTypeWithFields.fields.length > 0 && (
                  <div>
                    <label className="block text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-3">
                      Details
                    </label>
                    <div className="space-y-4">
                      {taskTypeWithFields.fields.map((field) => (
                        <DynamicField
                          key={field.id}
                          field={{
                            key: field.key,
                            label: field.label,
                            field_type: field.field_type,
                            required: field.required,
                            options: field.options || undefined,
                          }}
                          value={customData[field.key]}
                          onChange={(value) => handleCustomFieldChange(field.key, value)}
                        />
                      ))}
                    </div>
                  </div>
                )}
              </div>

              {/* Right Column - Status, Estimation, Release, GitHub, Dependencies */}
              <div className="space-y-6">
                {/* Status - Workflow Style */}
                <div>
                  <label className="block text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-3">
                    Workflow State
                  </label>
                  <WorkflowSelector
                    workflow={workflow}
                    currentStatus={status}
                    onStatusChange={(newStatus: string) => {
                      setStatus(newStatus);
                      handleFieldChange('status', newStatus);
                    }}
                    isLoading={updateMutation.isPending}
                  />
                </div>

                {/* Estimation */}
                <div>
                  <label className="block text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-2">
                    Estimation
                  </label>
                  <input
                    type="number"
                    value={estimation ?? ''}
                    onChange={(e) => setEstimation(e.target.value ? Number(e.target.value) : null)}
                    onBlur={() => {
                      if (estimation !== task.estimation) {
                        handleFieldChange('estimation', estimation);
                      }
                    }}
                    placeholder="Points"
                    className="w-full px-3 py-2.5 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white text-sm"
                  />
                </div>

                {/* Release */}
                <div>
                  <label className="block text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-2">
                    Release
                  </label>
                  <SelectInput
                    value={releaseId || ''}
                    onChange={(e) => {
                      const newReleaseId = e.target.value ? Number(e.target.value) : null;
                      setReleaseId(newReleaseId);
                      handleFieldChange('release_id', newReleaseId);
                    }}
                    options={(releases?.items || []).map(r => ({ 
                      value: r.id, 
                      label: `${r.version} - ${r.title}` 
                    }))}
                    placeholder="Unassigned"
                  />
                </div>

                {/* Development / GitHub Links */}
                <div>
                  <label className="block text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-2">
                    Development
                  </label>
                  {fullTask?.github_links && fullTask.github_links.length > 0 ? (
                    <div className="space-y-2">
                      {fullTask.github_links.map((link) => (
                        <div
                          key={link.id}
                          className="flex items-center justify-between p-2.5 bg-green-50 dark:bg-green-900/20 text-green-700 dark:text-green-400 rounded-lg"
                        >
                          <a
                            href={link.url}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="flex items-center gap-2 text-sm hover:underline"
                          >
                            <GitBranch className="h-4 w-4" />
                            {fullTask.github_links?.length || 0} Pull Request{(fullTask.github_links?.length || 0) > 1 ? 's' : ''} linked
                          </a>
                          <button className="text-green-600 dark:text-green-400 hover:text-green-800 dark:hover:text-green-300">
                            <X className="h-4 w-4" />
                          </button>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <p className="text-sm text-gray-400 dark:text-gray-500">No PRs linked</p>
                  )}
                </div>

                {/* Dependencies Section Header */}
                <div>
                  <div className="flex items-center justify-between mb-3">
                    <label className="block text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                      Dependencies
                    </label>
                    <button
                      onClick={() => setShowAddDependencyModal(true)}
                      className="flex items-center gap-1 px-2 py-1 text-xs bg-primary-600 text-white rounded hover:bg-primary-700 transition-colors"
                    >
                      <Plus className="h-3 w-3" />
                      Add
                    </button>
                  </div>

                  {/* Depends On (is impacted by) */}
                  <div className="space-y-3">
                    <div>
                      <h4 className="text-xs font-medium text-gray-600 dark:text-gray-400 mb-2 flex items-center gap-1">
                        <ArrowRight className="h-3 w-3" />
                        Depends On <span className="text-gray-400 font-normal">(is impacted by)</span>
                      </h4>
                      {fullTask?.dependencies && fullTask.dependencies.length > 0 ? (
                        <div className="space-y-1">
                          {fullTask.dependencies.map((dep) => (
                            <div
                              key={dep.id}
                              className="flex items-center justify-between p-2 bg-gray-50 dark:bg-gray-700/50 rounded-lg group"
                            >
                              <div className="flex items-center gap-2 text-sm min-w-0">
                                <div className="bg-blue-100 dark:bg-blue-900/30 p-1.5 rounded flex-shrink-0">
                                  <CheckSquare className="h-3 w-3 text-blue-600 dark:text-blue-400" />
                                </div>
                                <span className="font-mono text-xs text-primary-600 dark:text-primary-400">{dep.display_id}</span>
                                <span className="truncate text-gray-700 dark:text-gray-300">{dep.title}</span>
                              </div>
                              <button
                                onClick={() => removeDependencyMutation.mutate(dep.id)}
                                className="p-1 text-gray-400 hover:text-red-600 dark:hover:text-red-400 opacity-0 group-hover:opacity-100 transition-opacity flex-shrink-0"
                                title="Remove dependency"
                              >
                                <X className="h-3 w-3" />
                              </button>
                            </div>
                          ))}
                        </div>
                      ) : (
                        <p className="text-xs text-gray-400 dark:text-gray-500 p-2 bg-gray-50 dark:bg-gray-700/50 rounded-lg">
                          No dependencies
                        </p>
                      )}
                    </div>

                    {/* Depended By (impacts) */}
                    <div>
                      <h4 className="text-xs font-medium text-gray-600 dark:text-gray-400 mb-2 flex items-center gap-1">
                        <ArrowLeft className="h-3 w-3" />
                        Depended By <span className="text-gray-400 font-normal">(impacts)</span>
                      </h4>
                      {fullTask?.dependents && fullTask.dependents.length > 0 ? (
                        <div className="space-y-1">
                          {fullTask.dependents.map((dep) => (
                            <div
                              key={dep.id}
                              className="flex items-center gap-2 p-2 bg-gray-50 dark:bg-gray-700/50 rounded-lg text-sm"
                            >
                              <div className="bg-purple-100 dark:bg-purple-900/30 p-1.5 rounded flex-shrink-0">
                                <CheckSquare className="h-3 w-3 text-purple-600 dark:text-purple-400" />
                              </div>
                              <span className="font-mono text-xs text-primary-600 dark:text-primary-400">{dep.display_id}</span>
                              <span className="truncate text-gray-700 dark:text-gray-300">{dep.title}</span>
                            </div>
                          ))}
                        </div>
                      ) : (
                        <p className="text-xs text-gray-400 dark:text-gray-500 p-2 bg-gray-50 dark:bg-gray-700/50 rounded-lg">
                          No tasks depend on this
                        </p>
                      )}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Add Dependency Modal */}
      <FormModal
        isOpen={showAddDependencyModal}
        onClose={() => setShowAddDependencyModal(false)}
        onSubmit={() => {}}
        title="Add Task Dependency"
        submitLabel=""
        cancelLabel="Close"
        size="lg"
      >
        {availableTasksForDependency.length === 0 ? (
          <EmptyState
            icon={CheckSquare}
            title="No available tasks"
            description="All tasks are already dependencies or there are no other tasks."
          />
        ) : (
          <div className="space-y-4">
            <div className="p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
              <p className="text-sm text-blue-800 dark:text-blue-200">
                <strong>Adding a dependency means:</strong> This task is <em>impacted by</em> the selected task.
                The selected task should ideally be completed before this one.
              </p>
            </div>
            <p className="text-sm text-gray-600 dark:text-gray-400">
              Select a task that this task depends on:
            </p>
            <div className="space-y-2 max-h-64 overflow-y-auto">
              {availableTasksForDependency.map((t) => (
                <button
                  key={t.id}
                  onClick={() => {
                    addDependencyMutation.mutate(t.id);
                    setShowAddDependencyModal(false);
                  }}
                  className="w-full flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700/50 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 text-left transition-colors"
                >
                  <div className="flex items-center gap-3 min-w-0">
                    <div className="bg-blue-100 dark:bg-blue-900/30 p-2 rounded-lg flex-shrink-0">
                      <CheckSquare className="h-4 w-4 text-blue-600 dark:text-blue-400" />
                    </div>
                    <div className="min-w-0">
                      <p className="font-medium text-gray-900 dark:text-white truncate">
                        <span className="text-gray-500 dark:text-gray-400 mr-2 font-mono text-sm">{t.display_id}</span>
                        {t.title}
                      </p>
                      <p className="text-xs text-gray-500 dark:text-gray-400">
                        {t.team?.name && <span className="text-primary-600 dark:text-primary-400">{t.team.name}</span>}
                        {t.team?.name && ' • '}
                        {t.status}
                      </p>
                    </div>
                  </div>
                  <Plus className="h-4 w-4 text-primary-600 flex-shrink-0" />
                </button>
              ))}
            </div>
          </div>
        )}
      </FormModal>
    </div>
  );
}