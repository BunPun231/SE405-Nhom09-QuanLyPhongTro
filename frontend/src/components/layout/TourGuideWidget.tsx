import { useState, useEffect } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import { useTourGuide, ONBOARDING_STEPS, SUB_STEPS, TENANT_ONBOARDING_STEPS, TENANT_SUB_STEPS } from "@/hooks/useTourGuide";
import {
  HelpCircle, ChevronDown, ChevronUp, Check, Play,
  BookOpen, Sparkles, X, ArrowRight, ExternalLink
} from "lucide-react";
import { Button } from "@/components/ui/Button";
import { useAuthStore } from "@/store/authStore";

export function TourGuideWidget() {
  const navigate = useNavigate();
  const location = useLocation();
  const { user } = useAuthStore();
  
  const {
    onboardingStatus,
    loading,
    currentStep,
    activeStepData,
    hasCompletedOnboarding,
    completeOnboarding,
    isGuideOpen,
    setIsGuideOpen,
    showCelebration,
    setShowCelebration,
    pageGuide,
    activeSubStepId,
    setActiveSubStepId,
    isDriverActive,
    localOverrideStep,
    setLocalOverrideStep,
    completeTenantOnboarding
  } = useTourGuide();

  const isTenant = !!(user && ((user.role as string) === "TENANT" || (user.role as string) === "RESIDENT"));
  const stepsList = isTenant ? TENANT_ONBOARDING_STEPS : ONBOARDING_STEPS;
  const subStepsList = isTenant ? TENANT_SUB_STEPS : SUB_STEPS;
  const tenantStep = isTenant ? currentStep : 1;

  // Pulse effect trigger for new steps
  const [pulse, setPulse] = useState(false);

  useEffect(() => {
    setPulse(true);
    const t = setTimeout(() => setPulse(false), 2000);
    return () => clearTimeout(t);
  }, [currentStep]);

  if (loading && !onboardingStatus && !isTenant) return null;

  const activeStepNumber = localOverrideStep !== null ? localOverrideStep : currentStep;

  // Helper to start/replay a specific step
  const startStepGuide = (stepNum: number) => {
    setLocalOverrideStep(stepNum);
    setIsGuideOpen(true);
    const firstSubStep = subStepsList.find(s => s.stage === stepNum);
    if (firstSubStep) {
      setActiveSubStepId(firstSubStep.id);
      const storageKey = isTenant ? "tenant_onboarding_substep" : "onboarding_substep";
      localStorage.setItem(storageKey, firstSubStep.id);
    }
    const targetStep = stepsList[stepNum - 1];
    if (targetStep && location.pathname !== targetStep.targetPath) {
      navigate(targetStep.targetPath);
    }
  };

  // Confetti Particle Celebration Component
  const ConfettiCelebration = () => {
    return (
      <div className="fixed inset-0 bg-slate-950/80 backdrop-blur-md flex items-center justify-center z-50 p-4 animate-fade-in">
        <style>{`
          @keyframes confetti-fall {
            0% { transform: translateY(-50px) rotate(0deg); opacity: 1; }
            100% { transform: translateY(100vh) rotate(720deg); opacity: 0; }
          }
          .confetti {
            position: fixed;
            width: 12px;
            height: 12px;
            animation: confetti-fall 4s linear infinite;
          }
        `}</style>
        {/* Generate dynamic confetti particles */}
        {Array.from({ length: 80 }).map((_, i) => {
          const left = Math.random() * 100;
          const colors = ["#8B5CF6", "#EC4899", "#10B981", "#3B82F6", "#F59E0B", "#EF4444"];
          const color = colors[Math.floor(Math.random() * colors.length)];
          const delay = Math.random() * 3;
          const duration = 3 + Math.random() * 3;
          return (
            <div
              key={i}
              className="confetti"
              style={{
                left: `${left}%`,
                top: `-20px`,
                backgroundColor: color,
                animationDelay: `${delay}s`,
                animationDuration: `${duration}s`,
                borderRadius: Math.random() > 0.5 ? "50%" : "2px"
              }}
            />
          );
        })}

        <div className="w-full max-w-lg bg-white border border-slate-100 shadow-2xl rounded-3xl p-8 text-center relative overflow-hidden font-sans">
          <div className="absolute top-0 inset-x-0 h-2 bg-gradient-to-r from-emerald-400 via-brand-deep to-violet-500" />
          
          <div className="w-24 h-24 rounded-full bg-emerald-100 border-4 border-emerald-400 flex items-center justify-center mx-auto text-emerald-600 text-5xl mb-6 shadow-xl shadow-emerald-50">
            <Sparkles size={48} className="animate-spin-slow text-emerald-500" />
          </div>

          <h2 className="text-3xl font-extrabold text-slate-800 font-display tracking-tight leading-tight">
            Quá Tuyệt Vời, Chúc Mừng Bác! 🎉
          </h2>
          
          <p className="text-slate-650 mt-4 text-base leading-relaxed">
            Bác đã hoàn thành xuất sắc <strong>6 chặng hướng dẫn</strong>, cấu hình thành công hệ thống tự động gạch nợ hóa đơn qua SePay và xuất hóa đơn đầu tiên!
          </p>

          <div className="mt-6 bg-slate-50 border border-slate-100 rounded-2xl p-4 text-left text-sm space-y-2 text-slate-600">
            <p className="font-bold text-slate-700 flex items-center gap-1.5">
              <Check size={16} className="text-emerald-500" /> Hệ thống của bác đã sẵn sàng:
            </p>
            <ul className="list-disc pl-5 space-y-1.5 font-sans">
              <li>Tự động sinh VietQR chuyển khoản chứa hóa đơn động.</li>
              <li>Thanh toán gạch nợ tự động trong 3 giây cực kỳ an toàn.</li>
              <li>Bảo mật cao với cơ chế xác thực HMAC-SHA256.</li>
            </ul>
          </div>

          <div className="mt-8 flex flex-col gap-3">
            <Button
              onClick={async () => {
                await completeOnboarding();
                setShowCelebration(false);
                navigate("/dashboard");
              }}
              className="w-full py-4 bg-brand-deep hover:bg-brand-deep/90 text-white font-extrabold text-base shadow-lg shadow-brand-deep/20 rounded-2xl transition-all hover:scale-[1.02]"
            >
              Bắt Đầu Quản Lý Thực Tế
            </Button>
          </div>
        </div>
      </div>
    );
  };

  const getStepStatus = (stepNum: number) => {
    if (isTenant) {
      if (hasCompletedOnboarding) return "done";
      return tenantStep > stepNum ? "done" : "todo";
    }
    if (!onboardingStatus) return "todo";
    switch (stepNum) {
      case 1: return onboardingStatus.hasMotel ? "done" : "todo";
      case 2: return onboardingStatus.hasSePayConfig ? "done" : "todo";
      case 3: return onboardingStatus.hasRooms ? "done" : "todo";
      case 4: return onboardingStatus.hasActiveContract ? "done" : "todo";
      case 5: return onboardingStatus.hasMeterReadings ? "done" : "todo";
      case 6: return onboardingStatus.hasInvoice ? "done" : "todo";
      default: return "todo";
    }
  };

  return (
    <>
      {showCelebration && <ConfettiCelebration />}

      <div className="fixed bottom-6 right-6 z-40 flex flex-col items-end gap-3 font-sans">
        {/* Expandable Dialog Guide Panel */}
        {isGuideOpen && !isDriverActive && (
          <div className="w-80 sm:w-96 bg-white border border-slate-100 shadow-2xl rounded-2xl overflow-hidden flex flex-col max-h-[500px] animate-fade-in border-t-4 border-t-brand-deep">
            {/* Header */}
            <div className="bg-slate-50 border-b border-slate-100 px-5 py-4 flex items-center justify-between">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-full bg-brand-deep/10 flex items-center justify-center text-brand-deep">
                  <HelpCircle size={18} />
                </div>
                <div>
                  <h4 className="font-extrabold text-slate-800 text-sm">Trợ lý Hướng dẫn</h4>
                  <p className="text-[10px] text-slate-400">
                    {isTenant ? "Theo dõi phòng & hóa đơn" : "Đồng hành cùng bác chủ trọ"}
                  </p>
                </div>
              </div>
              <button
                onClick={() => setIsGuideOpen(false)}
                className="text-slate-400 hover:text-slate-600 transition-colors p-1"
              >
                <X size={16} />
              </button>
            </div>

            {/* Content Body */}
            <div className="flex-1 overflow-y-auto p-5 space-y-5">
              {!hasCompletedOnboarding || localOverrideStep !== null ? (
                /* ONBOARDING FLOW MODE (6 STEPS) */
                <div className="space-y-4">
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-bold text-slate-500 uppercase">
                      {isTenant ? "Tiến trình hướng dẫn" : "Tiến trình thiết lập"}
                    </span>
                    <span className="text-xs font-extrabold text-brand-deep">
                      {stepsList.filter(s => getStepStatus(s.stepNumber) === "done").length}/{stepsList.length} Hoàn thành
                    </span>
                  </div>

                  {/* Override Warning/Banner */}
                  {localOverrideStep !== null && (
                    <div className="bg-amber-50 border border-amber-200 rounded-xl p-3 text-xs text-amber-800 flex flex-col gap-2 animate-fade-in">
                      <div className="font-semibold flex items-center gap-1">
                        <Sparkles size={14} className="text-amber-600 shrink-0" />
                        <span>Bác đang xem lại Chặng {localOverrideStep}</span>
                      </div>
                      <button
                        onClick={() => setLocalOverrideStep(null)}
                        className="w-full py-1.5 bg-amber-600 hover:bg-amber-700 text-white rounded-lg font-bold text-[11px] transition-colors"
                      >
                        Quay lại chặng đang làm (Chặng {currentStep})
                      </button>
                    </div>
                  )}

                  {/* Checklist steps */}
                  <div className="space-y-2">
                    {stepsList.map((step) => {
                      const status = getStepStatus(step.stepNumber);
                      const isActive = activeStepNumber === step.stepNumber;
                      return (
                        <div
                          key={step.stepNumber}
                          onClick={() => startStepGuide(step.stepNumber)}
                          className={`border rounded-xl p-3 transition-all cursor-pointer ${
                            isActive
                              ? "border-brand-deep bg-brand-deep/5"
                              : "border-slate-100 hover:bg-slate-50"
                          }`}
                        >
                          <div className="flex items-center gap-3">
                            {status === "done" ? (
                              <div className="w-5 h-5 rounded-full bg-emerald-500 text-white flex items-center justify-center flex-shrink-0">
                                <Check size={12} strokeWidth={3} />
                              </div>
                            ) : (
                              <div className={`w-5 h-5 rounded-full border flex items-center justify-center text-xs font-bold flex-shrink-0 ${
                                isActive
                                  ? "border-brand-deep text-brand-deep bg-white"
                                  : "border-slate-350 text-slate-400"
                              }`}>
                                {step.stepNumber}
                              </div>
                            )}
                            <span className={`text-xs font-bold flex-1 ${isActive ? "text-brand-deep font-extrabold" : "text-slate-700"}`}>
                              {step.title}
                            </span>
                          </div>

                          {/* Extra info for active step */}
                          {isActive && (
                            <div className="mt-2.5 pl-8 space-y-2.5" onClick={(e) => e.stopPropagation()}>
                              <p className="text-[11px] text-slate-600 leading-relaxed font-normal">
                                {step.description}
                              </p>
                              <div className="bg-white/70 p-2 rounded border border-brand-deep/10 text-[10px] text-slate-500 italic leading-relaxed">
                                💡 <strong>Gợi ý:</strong> {step.hint}
                              </div>

                              {/* Render sub-steps progress */}
                              <div className="space-y-1.5 border-t border-slate-200/60 pt-2.5">
                                <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Các bước thực hiện:</span>
                                {subStepsList.filter(s => s.stage === step.stepNumber).map(sub => {
                                  const isSubActive = activeSubStepId === sub.id;
                                  const isSubDone = parseFloat(activeSubStepId) > parseFloat(sub.id);
                                  
                                  return (
                                    <div key={sub.id} className="flex items-center gap-2 text-xs">
                                      <div className={`w-4 h-4 rounded-full flex items-center justify-center text-[9px] font-bold shrink-0 ${
                                        isSubDone 
                                          ? "bg-emerald-500 text-white" 
                                          : isSubActive 
                                            ? "bg-brand-deep text-white" 
                                            : "bg-slate-100 text-slate-400"
                                      }`}>
                                        {isSubDone ? "✓" : sub.subStep}
                                      </div>
                                      <span className={`text-[11px] ${
                                        isSubActive 
                                          ? "text-brand-deep font-extrabold" 
                                          : isSubDone 
                                            ? "text-slate-400 line-through font-normal" 
                                            : "text-slate-650 font-normal"
                                      }`}>
                                        {sub.title}
                                      </span>
                                    </div>
                                  );
                                })}
                              </div>

                              <button
                                onClick={() => startStepGuide(step.stepNumber)}
                                className="w-full flex items-center justify-center gap-1.5 py-1.5 bg-brand-deep hover:bg-brand-deep/90 text-white text-xs font-bold rounded-lg transition-colors shadow-sm mt-2"
                              >
                                <span>{step.actionLabel}</span>
                                <Play size={12} fill="white" />
                              </button>
                            </div>
                          )}
                        </div>
                      );
                    })}
                  </div>

                  {/* Restart guide button */}
                  <div className="pt-2 border-t border-slate-100">
                    <button
                      onClick={() => startStepGuide(1)}
                      className="w-full py-2 border border-brand-deep text-brand-deep hover:bg-brand-deep/5 rounded-xl font-bold text-xs transition-colors flex items-center justify-center gap-1.5 cursor-pointer"
                    >
                      <Play size={12} className="fill-brand-deep" />
                      Làm lại hướng dẫn từ đầu
                    </button>
                  </div>
                </div>
              ) : (
                /* PAGE SPECIFIC GUIDANCE MODE (AFTER ONBOARDING) */
                <div className="space-y-4">
                  {pageGuide ? (
                    <div className="space-y-3">
                      <div className="flex items-center gap-2 border-b border-slate-100 pb-2">
                        <BookOpen size={16} className="text-brand-deep" />
                        <span className="text-xs font-bold text-slate-700 uppercase">
                          Hướng dẫn cho: {pageGuide.title}
                        </span>
                      </div>
                      <div className="space-y-2.5">
                        {pageGuide.tips.map((tip, idx) => (
                          <div key={idx} className="flex gap-2 text-xs text-slate-650 leading-relaxed">
                            <span className="text-brand-deep font-extrabold">•</span>
                            <p>{tip}</p>
                          </div>
                        ))}
                      </div>
                    </div>
                  ) : (
                    <div className="py-4 text-center text-slate-500 space-y-1">
                      <HelpCircle size={24} className="mx-auto text-slate-350" />
                      <p className="text-xs font-medium">Bác đang ở trang chưa có tài liệu cụ thể.</p>
                      <p className="text-[10px] text-slate-400">Hãy chuyển qua các chức năng chính để xem gợi ý.</p>
                    </div>
                  )}

                  {/* Option to view onboarding again */}
                  <div className="pt-3 border-t border-slate-100 flex flex-col gap-2">
                    <button
                      onClick={() => startStepGuide(1)}
                      className="w-full text-center text-xs font-bold text-brand-deep hover:underline flex items-center justify-center gap-1 cursor-pointer"
                    >
                      <Sparkles size={12} />
                      <span>Xem lại luồng Onboarding (6 Chặng)</span>
                    </button>
                    <a
                      href="https://sepay.vn"
                      target="_blank"
                      rel="noopener noreferrer"
                      className="w-full text-center text-[10px] text-slate-450 hover:underline flex items-center justify-center gap-0.5"
                    >
                      <span>Tài liệu SePay.vn</span>
                      <ExternalLink size={10} />
                    </a>
                  </div>
                </div>
              )}
            </div>

            {/* Footer action */}
            {!hasCompletedOnboarding && currentStep === 7 && (
              <div className="p-4 bg-emerald-50 border-t border-emerald-100 text-center">
                <Button
                  onClick={() => setShowCelebration(true)}
                  className="w-full bg-emerald-600 hover:bg-emerald-700 text-white font-extrabold text-xs py-2 shadow-md flex items-center justify-center gap-1"
                >
                  <Sparkles size={14} />
                  <span>Hoàn tất thiết lập & Nhận phòng làm việc</span>
                </Button>
              </div>
            )}
          </div>
        )}

        {/* Floating Bubble Button */}
        <button
          onClick={() => setIsGuideOpen(!isGuideOpen)}
          className={`flex items-center gap-2 px-4 py-3 bg-brand-deep hover:bg-brand-deep/90 text-white rounded-full shadow-2xl transition-all active:scale-95 font-semibold text-xs border border-white/10 group cursor-pointer ${
            pulse ? "animate-bounce ring-4 ring-brand-deep/30" : "hover:translate-y-[-2px]"
          }`}
        >
          <HelpCircle size={18} className="group-hover:rotate-12 transition-transform" />
          <span>❓ Trợ lý Hướng dẫn</span>
          {!hasCompletedOnboarding && currentStep <= 6 && (
            <span className="w-5 h-5 bg-rose-500 text-white text-[10px] font-bold rounded-full flex items-center justify-center animate-pulse">
              {currentStep}
            </span>
          )}
        </button>
      </div>
    </>
  );
}
